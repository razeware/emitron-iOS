/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Combine

final class DynamicContentViewModel: ObservableObject {
  private let contentId: Int
  private let repository: Repository
  private let downloadAction: DownloadAction
  
  private var dynamicContentState: DynamicContentState?
  
  var state: DataState = .initial
  @Published var viewProgress: ContentViewProgressDisplayable = .notStarted
  @Published var downloadProgress: DownloadProgressDisplayable = .notDownloadable
  @Published var bookmarked: Bool = false
  
  var subscriptions = Set<AnyCancellable>()
  
  init(contentId: Int, repository: Repository, downloadAction: DownloadAction) {
    self.contentId = contentId
    self.repository = repository
    self.downloadAction = downloadAction
  }
  
  func initialiseIfRequired() {
    if state == .initial {
      reload()
    }
  }
  
  func reload() {
    self.state = .loading
    subscriptions.forEach({ $0.cancel() })
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  private func configureSubscriptions() {
    repository
      .contentDynamicState(for: contentId)
      .sink(receiveCompletion: { (completion) in
        self.state = .failed
        Failure
          .repositoryLoad(from: "DynamicContentViewModel", reason: "Unable to retrieve dynamic download content: \(completion)")
          .log()
      }) { (contentState) in
        self.viewProgress = ContentViewProgressDisplayable(progression: contentState.progression)
        self.downloadProgress = DownloadProgressDisplayable(download: contentState.download)
        self.bookmarked = contentState.bookmark != nil
        self.dynamicContentState = contentState
        self.state = .hasData
      }
      .store(in: &subscriptions)
  }
  
  func downloadTapped() {
    guard state == .hasData else { return }
    
    do {
      switch downloadProgress {
      case .downloadable:
        downloadAction.requestDownload(contentId: contentId) { (contentId) -> (ContentPersistableState?) in
          do {
            return try self.repository.contentPersistableState(for: contentId)
          } catch {
            Failure
              .repositoryLoad(from: String(describing: type(of: self)), reason: "Unable to locate presistable state in cache:  \(error)")
              .log()
            return nil
          }
        }
      case .enqueued, .inProgress:
        try downloadAction.cancelDownload(contentId: contentId)
      case .downloaded:
        try downloadAction.deleteDownload(contentId: contentId)
      case .notDownloadable:
        // No-op
        return
      }
    } catch {
      Failure
        .repositoryLoad(from: String(describing: type(of: self)), reason: "Unable to perform download action:  \(error)")
        .log()
    }
  }
  
  func bookmarkTapped() {
    guard state == .hasData  else { return }
    
    // TODO
  }
  
  func completedTapped() {
    guard state == .hasData else { return }
    
    // TODO
  }
}
