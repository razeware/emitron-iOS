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

class BookmarksMC {
  
  // MARK: - Properties
  private let client: RWAPI
  private let bookmarksService: BookmarksService
  private let dataManager: DataManager?
    
  // MARK: - Initializers
  init(user: UserModel, dataManager: DataManager? = DataManager.current) {
    self.client = RWAPI(authToken: user.token)
    self.bookmarksService = BookmarksService(client: self.client)
    self.dataManager = dataManager
  }
  
  func toggleBookmark(for content: ContentDetailsModel) {

    if !content.bookmarked {
      bookmarksService.makeBookmark(for: content.id) { result in
        switch result {
        case .failure(let error):
          Failure
          .fetch(from: "ContentDetailsVM_makeBookmark", reason: error.localizedDescription)
          .log(additionalParams: nil)
        case .success(let bookmark):
          content.bookmark = bookmark
          content.bookmarked = true
          guard let dataManager = self.dataManager else { return }
          dataManager.disseminateUpdates(for: content)
        }
      }
    } else {
      guard let id = content.bookmarkId else { return }
      // For deleting the bookmark, we have to use the original bookmark id
      bookmarksService.destroyBookmark(for: id) { result in
        switch result {
        case .failure(let error):
          Failure
          .fetch(from: "ContentDetailsVM_destroyBookmark", reason: error.localizedDescription)
          .log(additionalParams: nil)
        case .success(_):
          content.bookmark = nil
          content.bookmarked = false
          guard let dataManager = self.dataManager else { return }
          dataManager.disseminateUpdates(for: content)
        }
      }
    }
  }
}

