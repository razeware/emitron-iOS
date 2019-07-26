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
import Firebase

class ContentsMC: NSObject, BindableObject {
  
  // MARK: - Properties
  private(set) var willChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    didSet {
      willChange.send(())
    }
  }
  
  private let client: RWAPI
  private let guardpost: Guardpost
  private let contentsService: ContentsService
  private(set) var data: [ContentDetail] = []
  private(set) var numTutorials: Int = 0
  private(set) var currentPage: Int = 1
  private(set) var defaultPageSize: Int = 20
  private(set) var currentParameters: [Parameter] = [] {
    didSet {
      loadContents(with: currentParameters)
    }
  }
  
  var filters: Filters {
    didSet {
      if oldValue.filters != filters.filters {
        currentParameters = oldValue.applied
      }
    }
  }
  
  // MARK: - Initializers
  init(guardpost: Guardpost) {
    self.guardpost = guardpost
    
    //TODO: Probably need to handle this better
    self.client = RWAPI(authToken: guardpost.currentUser?.token ?? "")
    self.contentsService = ContentsService(client: self.client)
    self.filters = Filters()
    super.init()
    
    loadContents()
  }
  
  func loadContents(with parameters: [Parameter] = Param.filter(by: [.contentTypes(types: [.collection, .screencast])]),
                    pageSize: Int? = nil,
                    offset: Int? = nil) {
    guard state != .loading else {
      return
    }
    
    state = .loading
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    var allParams = parameters
    allParams.append(pageParam)
    
    // Don't load more contents if we've reached the end of the results
    guard data.isEmpty || data.count <= numTutorials  else { return }
    
    contentsService.allContents(parameters: allParams) { [weak self] result in
      
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Analytics.logEvent("error", parameters: [
          AnalyticsParameterItemName: "Failed to load contents!",
          AnalyticsParameterContent: "Parameters: \(parameters)",
          "description": error.localizedDescription
        ])
      case .success(let contentsTuple):
        // When filtering, do we just re-do the request, or append?
        if allParams == self.currentParameters {
          let currentContents = self.data
          self.data = currentContents + contentsTuple.contents
        } else {
          self.data = contentsTuple.contents
        }
        self.numTutorials = contentsTuple.totalNumber
        self.currentPage += 1
        self.state = .hasData
      }
    }
  }
}
