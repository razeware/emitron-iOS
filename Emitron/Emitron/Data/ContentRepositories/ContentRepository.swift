// Copyright (c) 2022 Kodeco Inc

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine

class ContentRepository: ObservableObject, ContentPaginatable {
  var invalidationPublisher: AnyPublisher<Void, Never>? { nil }

  let repository: Repository
  let messageBus: MessageBus
  let settingsManager: SettingsManager
  let sessionController: SessionController
  private(set) weak var syncAction: SyncAction?

  private let contentsService: ContentsService
  private let downloadService: DownloadService
  private let serviceAdapter: ContentServiceAdapter!

  private var contentIDs: [Int] = []
  private var contentSubscription: AnyCancellable?
  // Provide a value for this in a subclass to subscribe to invalidation notifications
  private var invalidationSubscription: AnyCancellable?

  // MARK: - ContentPaginatable

  private(set) var currentPage = 1

  var state: DataState = .initial

  private(set) var totalContentNum = 0

  @Published var contents: [ContentListDisplayable] = []

  func loadMore() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    guard contentIDs.isEmpty || contentIDs.count <= totalContentNum else {
      return
    }
    
    state = .loadingAdditional
    currentPage += 1
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    let allParams = nonPaginationParameters + [pageParam]

    Task {
      do {
        let (newContentIDs, cacheUpdate, totalResultCount)
          = try await serviceAdapter.findContent(parameters: allParams)
        contentIDs += newContentIDs
        contentSubscription?.cancel()
        repository.apply(update: cacheUpdate)
        totalContentNum = totalResultCount
        state = .hasData
        configureContentSubscription()
      } catch {
        currentPage -= 1
        state = .failed
        Failure
          .fetch(from: Self.self, reason: error.localizedDescription)
          .log()
      }
    }
  }
  
  func reload() {
    if [.loading, .loadingAdditional].contains(state) {
      return
    }
    
    state = .loading
    
    // Reset current page to 1
    currentPage = startingPage

    Task {
      do {
        let (newContentIDs, cacheUpdate, totalResultCount)
          = try await serviceAdapter.findContent(parameters: nonPaginationParameters)
        contentIDs = newContentIDs
        contentSubscription?.cancel()
        repository.apply(update: cacheUpdate)
        totalContentNum = totalResultCount
        state = .hasData
        configureContentSubscription()
      } catch {
        self.state = .failed
        Failure
          .fetch(from: Self.self, reason: error.localizedDescription)
          .log()
      }
    }
  }

  // MARK: -

  var nonPaginationParameters: [Parameter] = [] {
    didSet {
      if state != .initial {
        reload()
      }
    }
  }
  
  init(
    repository: Repository,
    contentsService: ContentsService,
    downloadService: DownloadService,
    syncAction: SyncAction,
    serviceAdapter: ContentServiceAdapter! = nil,
    messageBus: MessageBus,
    settingsManager: SettingsManager,
    sessionController: SessionController
  ) {
    self.repository = repository
    self.contentsService = contentsService
    self.downloadService = downloadService
    self.syncAction = syncAction
    self.serviceAdapter = serviceAdapter
    self.messageBus = messageBus
    self.settingsManager = settingsManager
    self.sessionController = sessionController
    configureInvalidationSubscription()
  }
  
  func childContentsViewModel(for contentID: Int) -> ChildContentsViewModel {
    // Default to using the cached version
    DataCacheChildContentsViewModel(
      parentContentID: contentID,
      downloadService: downloadService,
      syncAction: syncAction,
      repository: repository,
      service: contentsService,
      messageBus: messageBus,
      settingsManager: settingsManager,
      sessionController: sessionController
    )
  }
}

// MARK: - internal
extension ContentRepository {
  var isEmpty: Bool { contents.isEmpty }

  func dynamicContentViewModel(for contentID: Int) -> DynamicContentViewModel {
    .init(
      contentID: contentID,
      repository: repository,
      downloadService: downloadService,
      syncAction: syncAction,
      messageBus: messageBus,
      settingsManager: settingsManager,
      sessionController: sessionController
    )
  }
}

// MARK: - private
private extension ContentRepository {
  func configureInvalidationSubscription() {
    if let invalidationPublisher = invalidationPublisher {
      invalidationSubscription = invalidationPublisher
        .sink { [weak self] in
          guard let self = self else { return }

          // If we're invalidating the cache then we need to set this to initial status again
          self.state = .dirty
          // We're not gonna broadcast this change. If you do it'll wreak havoc with the content
          // list and nav view—where the nav link for the currently displayed detail view disappears
          // from underneath us. Instead we check the state of this repo each time the content
          // listing appears. This doesn't feel that great, but it's what seems to work.
        }
    }
  }

  func configureContentSubscription() {
    contentSubscription = repository
      .contentSummaryState(for: contentIDs)
      .removeDuplicates()
      .sink(
        receiveCompletion: { error in
          Failure
            .repositoryLoad(from: Self.self, reason: "Unable to receive content summary update: \(error)")
            .log()
        },
        receiveValue: { [weak self] contentSummaryStates in
          guard let self = self else { return }

          self.contents = contentSummaryStates
        }
      )
  }
}
