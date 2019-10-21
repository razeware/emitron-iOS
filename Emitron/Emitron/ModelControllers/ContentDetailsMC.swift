/// Copyright (c) 2019 Razeware LLC
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
import SwiftUI
import Combine

class ContentSummaryMC: NSObject, ObservableObject, Identifiable {

  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }

  private let client: RWAPI
  private let guardpost: Guardpost
  private let contentsService: ContentsService
  private let bookmarksMC: BookmarksMC
  private(set) var data: ContentDetailsModel
  
  private var bookmarksSubscriber: AnyCancellable?

  // MARK: - Initializers
  init(guardpost: Guardpost,
       partialContentDetail: ContentDetailsModel) {
    self.guardpost = guardpost
    self.client = RWAPI(authToken: guardpost.currentUser?.token ?? "")
    self.contentsService = ContentsService(client: self.client)
    self.data = partialContentDetail
    self.data.isDownloaded = partialContentDetail.isDownloaded
    self.bookmarksMC = BookmarksMC(guardpost: guardpost)

    super.init()
    
    // If the partial content detail is actually the full details model; don't reload
    // If childContents > 0 AND there are groupd on the content, it's been fully loadeed
    if !partialContentDetail.needsDetails {
      self.state = .hasData
    }
  }

  // MARK: - Internal
  func getContentSummary(completion: ((ContentDetailsModel) -> Void)? = nil) {
    if case(.loading) = state {
      return
    }

    state = .loading

    contentsService.contentDetails(for: data.id) { [weak self] result in

      guard let self = self else {
        return
      }

      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "ContentDetailsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let contentDetails):
        self.data = contentDetails
        self.state = .hasData
        completion?(contentDetails)
      }
    }
  }
  
  func toggleBookmark(for model: ContentDetailsModel, completion: @escaping (ContentDetailsModel) -> Void) {
    bookmarksMC.toggleBookmark(for: model) { [weak self] newModel in
      guard let self = self else { return }
      
      self.data = newModel
      self.objectWillChange.send(())
      completion(newModel)
    }
  }
}
