// Copyright (c) 2022 Razeware LLC
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
  private let downloadAction: DownloadAction
  private let serviceAdapter: ContentServiceAdapter!

  private var contentIDs: [Int] = []
  private var contentSubscription: AnyCancellable?
  // Provide a value for this in a subclass to subscribe to invalidation notifications
  private var invalidationSubscription: AnyCancellable?

  // MARK: - ContentPaginatable

  private(set) var currentPage = 1

  // This should be @Published too, but it crashes the compiler (Version 11.3 (11C29))
  // Let's see if we actually need it to be @Published...
  var state: DataState = .initial

  private(set) var totalContentNum = 0

  // This should be @Published, but it /sometimes/ crashes the app with EXC_BAD_ACCESS
  // when you try and reference it. Which is handy.
  var contents: [ContentListDisplayable] = [] {
    willSet {
      objectWillChange.send()
    }
  }

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
    
    serviceAdapter.findContent(parameters: allParams) { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        self.currentPage -= 1
        self.state = .failed
        self.objectWillChange.send()
        Failure
          .fetch(from: Self.self, reason: error.localizedDescription)
          .log()
      case .success(let (newContentIDs, cacheUpdate, totalResultCount)):
        self.contentIDs += newContentIDs
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalResultCount
        self.state = .hasData
        self.configureContentSubscription()
      }
    }
  }
  
  func reload() {
    if [.loading, .loadingAdditional].contains(state) {
      return
    }
    
    state = .loading
    // `state` can't be @Published, so we have to do this manually
    objectWillChange.send()
    
    // Reset current page to 1
    currentPage = startingPage
    
    serviceAdapter.findContent(parameters: nonPaginationParameters) { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        self.objectWillChange.send()
        Failure
          .fetch(from: Self.self, reason: error.localizedDescription)
          .log()
      case .success(let (newContentIDs, cacheUpdate, totalResultCount)):
        self.contentIDs = newContentIDs
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalResultCount
        self.state = .hasData
        self.configureContentSubscription()
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
    downloadAction: DownloadAction,
    syncAction: SyncAction,
    serviceAdapter: ContentServiceAdapter! = nil,
    messageBus: MessageBus,
    settingsManager: SettingsManager,
    sessionController: SessionController
  ) {
    self.repository = repository
    self.contentsService = contentsService
    self.downloadAction = downloadAction
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
      downloadAction: downloadAction,
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
      downloadAction: downloadAction,
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
          self.state = .initial
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
