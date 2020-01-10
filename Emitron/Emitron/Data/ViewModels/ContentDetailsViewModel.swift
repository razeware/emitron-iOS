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

// It'd be lovely if this could be a protocol. But in order to
// make it an ObservableObject, (which has associated type
// dependencies) it's easier to build a class hierarchy
class ContentDetailsViewModel: ObservableObject {
  let contentId: Int
  let downloadAction: DownloadAction
  
  @Published var content: ContentDetailDisplayable?
  @Published var childContents: [ContentListDisplayable] = [ContentListDisplayable]()
  // This should be @Published too, but it crashes the compiler (Version 11.3 (11C29))
  // Let's see if we actually need it to be @Published...
  var state: DataState = .initial
  
  var subscriptions = Set<AnyCancellable>()
  let childContentsPublishers = PassthroughSubject<AnyPublisher<[ContentSummaryState], Error>, Error>()
  
  init(contentId: Int, downloadAction: DownloadAction) {
    self.contentId = contentId
    self.downloadAction = downloadAction
  }

  func reload() {
    self.state = .loading
    subscriptions.forEach({ $0.cancel() })
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  func configureSubscriptions() {
    fatalError("Override this in a subclass please.")
  }

  func requestDownload(contentId: Int? = nil) {
    fatalError("Override this in a subclass please.")
  }
  
  func deleteDownload(contentId: Int? = nil) {
    let deleteId = contentId ?? self.contentId
    downloadAction.deleteDownload(contentId: deleteId)
  }
}

