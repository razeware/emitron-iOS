// Copyright (c) 2019 Razeware LLC
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

final class DownloadRepository: ContentRepository {
  let downloadService: DownloadService
  
  private var contentSubscription: AnyCancellable?
  
  init(repository: Repository,
       contentsService: ContentsService,
       downloadService: DownloadService,
       syncAction: SyncAction) {
    self.downloadService = downloadService
    // Don't need the repository or the service adapter
    super.init(repository: repository,
               contentsService: contentsService,
               downloadAction: downloadService,
               syncAction: syncAction,
               serviceAdapter: nil)
  }
  
  override func loadMore() {
    // Do nothing
  }
  
  override func reload() {
    self.state = .loading
    self.contentSubscription?.cancel()
    configureSubscription()
  }
  
  override func childContentsViewModel(for contentId: Int) -> ChildContentsViewModel {
    // For donwloaded content, we need to tell it to use the DB, not the service
    PersistenceStoreChildContentsViewModel(
      parentContentId: contentId,
      downloadAction: downloadService,
      syncAction: syncAction,
      repository: repository
    )
  }
  
  private func configureSubscription() {
    self.contentSubscription =
      self.downloadService
        .downloadList()
        .sink(receiveCompletion: { [weak self] error in
          guard let self = self else { return }
          self.state = .failed
          Failure
            .loadFromPersistentStore(from: String(describing: type(of: self)), reason: "Unable to retrieve download content summaries: \(error)")
            .log()
        }, receiveValue: { [weak self] contentSummaryStates in
          guard let self = self else { return }
          self.contents = contentSummaryStates
          self.state = .hasData
        })
  }
}
