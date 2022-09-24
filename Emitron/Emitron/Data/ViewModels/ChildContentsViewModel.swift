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

class ChildContentsViewModel: ObservableObject {
  let parentContentID: Int
  let downloadService: DownloadService
  weak var syncAction: SyncAction?
  let repository: Repository
  let messageBus: MessageBus
  let settingsManager: SettingsManager
  let sessionController: SessionController
  
  @Published var state: DataState = .initial
  @Published var groups: [GroupDisplayable] = []
  @Published var contents: [ChildContentListDisplayable] = []
  
  private var subscriptions = Set<AnyCancellable>()

  init(
    parentContentID: Int,
    downloadService: DownloadService,
    syncAction: SyncAction?,
    repository: Repository,
    messageBus: MessageBus,
    settingsManager: SettingsManager,
    sessionController: SessionController
  ) {
    self.parentContentID = parentContentID
    self.downloadService = downloadService
    self.syncAction = syncAction
    self.repository = repository
    self.messageBus = messageBus
    self.settingsManager = settingsManager
    self.sessionController = sessionController
  }

  func loadContentDetailsIntoCache() {
    preconditionFailure("Override in a subclass please.")
  }
}

// MARK: - internal
extension ChildContentsViewModel {
  func initialiseIfRequired() {
    if state == .initial {
      reload()
    }
  }
  
  func reload() {
    state = .loading
    subscriptions.forEach { $0.cancel() }
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  func contents(for groupID: Int) -> [ChildContentListDisplayable] {
    contents.filter({ $0.groupID == groupID })
  }
  
  func configureSubscriptions() {
    repository
      .childContentsState(for: parentContentID)
      .sink(
        receiveCompletion: { [weak self] completion in
          guard let self else { return }

          switch completion {
          case .failure(let error as DataCacheError) where error == .cacheMiss:
            self.loadContentDetailsIntoCache()
          default:
            self.state = .failed
            Failure
              .repositoryLoad(from: Self.self, reason: "Unable to retrieve download content detail: \(completion)")
              .log()
          }
        },
        receiveValue: { [weak self] childContentsState in
          guard let self else { return }

          self.state = .hasData
          self.contents = childContentsState.contents
          self.groups = childContentsState.groups
        }
      )
      .store(in: &subscriptions)
  }
  
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
