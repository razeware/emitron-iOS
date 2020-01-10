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

final class DownloadContentDetailsViewModel: ContentDetailsViewModel {
  private let service: DownloadService
  
  init(contentId: Int, service: DownloadService) {
    self.service = service
    
    super.init(contentId: contentId, downloadAction: service)
  }
  
  override func configureSubscriptions() {
    service.downloadedContentDetail(for: contentId)
      .sink(receiveCompletion: { [weak self] (error) in
      guard let self = self else { return }
      
      self.state = .failed
      Failure
        .repositoryLoad(from: "DownloadContentDetailsViewModel", reason: "Unable to retrieve download content detail: \(error)")
        .log()
    }, receiveValue: { [weak self] (contentDetailState) in
      guard let self = self else { return }
      
      self.state = .hasData
      self.content = contentDetailState
    })
      .store(in: &subscriptions)
    
    self.$content
      .compactMap({ $0 })
      .map(\ContentDetailDisplayable.childContents)
      .removeDuplicates()
      .map({ $0.map({ content in content.id }) })
      .sink(receiveValue: { [weak self] (childContentIds) in
        guard let self = self else { return }
        self.state = .loadingAdditional
        self.childContentsPublishers.send(
          self.service.contentSummaries(for: childContentIds)
        )
      })
      .store(in: &subscriptions)
    
    childContentsPublishers
      .switchToLatest()
      .sink(receiveCompletion: { [weak self] (error) in
        guard let self = self else { return }

        self.state = .failed
        Failure
          .repositoryLoad(from: "DownloadContentDetailsViewModel", reason: "Unable to retrieve download child contents: \(error)")
          .log()
      }, receiveValue: { [weak self] (contentSumaryStates) in
        guard let self = self else { return }
        self.state = .hasData
        self.childContents = contentSumaryStates
      })
      .store(in: &subscriptions)
  }
  
  override func requestDownload(contentId: Int? = nil) {
    // TODO: Do we need to support this
    Failure
      .unsupportedAction(from: String(describing: type(of: self)), reason: "Unable to request a download from a downloaded view model.")
      .log()
  }
}
