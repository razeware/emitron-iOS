// Copyright (c) 2020 Razeware LLC
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
  let parentContentId: Int
  let downloadAction: DownloadAction
  weak var syncAction: SyncAction?
  let repository: Repository
  
  var state: DataState = .initial
  @Published var groups: [GroupDisplayable] = []
  @Published var contents: [ChildContentListDisplayable] = []
  
  var subscriptions = Set<AnyCancellable>()
  
  init(parentContentId: Int,
       downloadAction: DownloadAction,
       syncAction: SyncAction?,
       repository: Repository) {
    self.parentContentId = parentContentId
    self.downloadAction = downloadAction
    self.syncAction = syncAction
    self.repository = repository
  }
  
  func initialiseIfRequired() {
    if state == .initial {
      reload()
    }
  }
  
  func reload() {
    self.state = .loading
    // Manually do this since can't have a @Published state property
    objectWillChange.send()
    
    subscriptions.forEach({ $0.cancel() })
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  func contents(for groupId: Int) -> [ChildContentListDisplayable] {
    contents.filter({ $0.groupId == groupId })
  }
  
  func configureSubscriptions() {
    repository
      .childContentsState(for: parentContentId)
      .sink(receiveCompletion: { [weak self] completion in
        guard let self = self else { return }
        if case .failure(let error) = completion, (error as? DataCacheError) == DataCacheError.cacheMiss {
          self.loadContentDetailsIntoCache()
        } else {
          self.state = .failed
          Failure
            .repositoryLoad(from: "DataCacheContentDetailsViewModel", reason: "Unable to retrieve download content detail: \(completion)")
            .log()
        }
      }, receiveValue: { [weak self] childContentsState in
        guard let self = self else { return }
        
        self.state = .hasData
        self.contents = childContentsState.contents
        self.groups = childContentsState.groups
      })
      .store(in: &subscriptions)
  }
  
  func loadContentDetailsIntoCache() {
    preconditionFailure("Override in a subclass please.")
  }
  
  func dynamicContentViewModel(for contentId: Int) -> DynamicContentViewModel {
    DynamicContentViewModel(
      contentId: contentId,
      repository: repository,
      downloadAction: downloadAction,
      syncAction: syncAction
    )
  }
}
