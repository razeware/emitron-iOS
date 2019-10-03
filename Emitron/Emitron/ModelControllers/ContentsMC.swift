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

class ContentsMC: NSObject, ObservableObject {
  
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
  private(set) var data: [ContentDetailsModel] = []
  private(set) var numTutorials: Int = 0
  
  // Pagination
  private var currentPage: Int = 1
  private let startingPage: Int = 1
  private(set) var defaultPageSize: Int = 20
  
  // Parameters
  private(set) var currentParameters: [Parameter] = [] {
    didSet {
      if oldValue != currentParameters {
        reloadContents()
      }
    }
  }
  
  private(set) var filters: Filters {
    didSet {
      currentParameters = filters.appliedParameters
    }
  }
    
  // MARK: - Initializers
  init(guardpost: Guardpost, filters: Filters) {
    self.guardpost = guardpost
    
    self.client = RWAPI(authToken: guardpost.currentUser?.token ?? "")
    self.contentsService = ContentsService(client: self.client)
    self.filters = filters
    self.currentParameters = filters.appliedParameters
    
    super.init()

    reloadContents()
  }
  
  func updateFilters(newFilters: Filters) {
    self.filters = newFilters
  }
  
  func loadMore() {
    
    if case(.loading) = state {
      return
    }
    
    state = .loading
    
    currentPage += 1
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    var allParams = currentParameters
    allParams.append(pageParam)
    
    contentsService.allContents(parameters: allParams) { [weak self] result in
      
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        self.currentPage = -1
        Failure
          .fetch(from: "ContentsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let contentsTuple):
        let currentContents = self.data
        self.data = currentContents + contentsTuple.contents
        self.numTutorials = contentsTuple.totalNumber
        self.state = .hasData
      }
    }
  }
  
  func reloadContents() {
    
    if case(.loading) = state {
      return
    }
    
    state = .loading
    
    // Don't load more contents if we've reached the end of the results
    guard data.isEmpty || data.count <= numTutorials else {
      return
    }
    
    // Reset current page to 1
    currentPage = startingPage
    
    contentsService.allContents(parameters: currentParameters) { [weak self] result in
      
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "ContentsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let contentsTuple):
        self.data = contentsTuple.contents
        self.numTutorials = contentsTuple.totalNumber
        self.state = .hasData
      }
    }
  }
}
