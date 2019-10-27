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
import CoreData

class BookmarkContentsMC: NSObject, ObservableObject, ContentPaginatable {
  
  var contentScreen: ContentScreen = .bookmarked
  
  var isLoadingMore: Bool = false
  
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }
  
  private let client: RWAPI
  private let bookmarksService: BookmarksService
  private(set) var data: [ContentDetailsModel] = []
  private(set) var totalContentNum: Int = 0
  
  // Pagination
  internal var currentPage: Int = 1
  
  // Parameters
  private var defaultParameters: [Parameter] {
    return Param.filters(for: [.contentTypes(types: [.collection, .screencast])])
  }
    
  // MARK: - Initializers
  init(user: UserModel) {
    self.client = RWAPI(authToken: user.token)
    self.bookmarksService = BookmarksService(client: self.client)
    
    super.init()

    reload()
  }
  
  func loadMore() {
    
    if case(.loading) = state {
      return
    }
    
    state = .loading
    currentPage += 1
    isLoadingMore = true
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    var allParams = defaultParameters
    allParams.append(pageParam)
    
    // Don't load more contents if we've reached the end of the results
    guard data.isEmpty || data.count <= totalContentNum else {
      return
    }
    
    bookmarksService.bookmarks(parameters: allParams) { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.isLoadingMore = false
        self.currentPage = -1
        self.state = .failed
        Failure
          .fetch(from: "BookmarksMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let bookmarksTuple):
        // When filtering, do we just re-do the request, or append?
        let currentContents = self.data
        self.data = currentContents + bookmarksTuple.bookmarks.compactMap { $0.content }
        self.addRelevantDetailsToContent()
        self.totalContentNum = bookmarksTuple.totalNumber
        self.isLoadingMore = false
        self.state = .hasData
      }
    }
  }
  
  func reload() {
    
    if case(.loading) = state {
      return
    }
    
    state = .loading
    isLoadingMore = false
    
    // Reset current page to 1
    currentPage = startingPage
    
    bookmarksService.bookmarks(parameters: defaultParameters) { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "BookmarksMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let bookmarksTuple):
        self.data = bookmarksTuple.bookmarks.compactMap { $0.content }
        self.addRelevantDetailsToContent()
        self.totalContentNum = bookmarksTuple.totalNumber
        self.state = .hasData
      }
    }
  }
  
  private func addRelevantDetailsToContent() {
    
    data.forEach { model in
      guard let dataManager = DataManager.current else { return }
      var relationships: [ContentRelatable] = []
      
      let domains = dataManager.domainsMC.data.filter { model.domainIDs.contains($0.id) }
      relationships.append(contentsOf: domains)
      
      model.addRelationships(for: relationships)
    }
  }
}

extension BookmarkContentsMC: ContentUpdatable {
  func updateEntryIfItExists(for content: ContentDetailsModel) {
    // If the entry doesn't exist and it has been bookmarked, add it
    guard let index = data.firstIndex(where: { $0.id == content.id } ) else {
      if content.bookmarked {
        data.append(content)
      }
      return
    }
    
    // If the entry exists, and it's been un-bookmarked, remove it
    if !content.bookmarked {
      data.remove(at: index)
    }
    
    // If the entry exists, and it is still bookmarked, that means another update to it has happened, in which case, replace
    // the entry at that index with the new content
    else {
      data[index] = content
    }
    
    objectWillChange.send(())
  }
}

