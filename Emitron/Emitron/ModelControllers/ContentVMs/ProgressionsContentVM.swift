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

// These classes are here as "wrappers" because I'm not sure how else to insert different objects of the same type into the environment

class InProgressContentVM: ProgressionsContentVM { }
class CompletedContentVM: ProgressionsContentVM { }

class ProgressionsContentVM: NSObject, ObservableObject, ContentPaginatable {
  var contentScreen: ContentScreen
  
  var isLoadingMore: Bool = false
  
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }
  
  private let client: RWAPI
  private let progressionsService: ProgressionsService
  private(set) var data: [ContentDetailsModel] = []
  private(set) var totalContentNum: Int = 0
  
  // Pagination
  internal var currentPage: Int = 1
  
  // Parameters
  private let completionStatus: CompletionStatus
  private var defaultParameters: [Parameter] {
    let filters = Param.filters(for: [.contentTypes(types: [.collection, .screencast])])
    let completionFilter = Param.filter(for: .completionStatus(status: completionStatus))
    return filters + [completionFilter]
  }
    
  // MARK: - Initializers
  init(user: UserModel, completionStatus: CompletionStatus) {
    self.completionStatus = completionStatus
    self.client = RWAPI(authToken: user.token)
    self.progressionsService = ProgressionsService(client: self.client)
    self.contentScreen = completionStatus == .inProgress ? ContentScreen.inProgress : .completed
    
    super.init()
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
    
    progressionsService.progressions(parameters: allParams) { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.isLoadingMore = false
        self.currentPage = -1
        self.state = .failed
        Failure
          .fetch(from: "ProgressionsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let progressionsTuple):
        // When filtering, do we just re-do the request, or append?
        let currentContents = self.data
        self.data = currentContents + progressionsTuple.progressions.compactMap { $0.content }
        self.addRelevantDetailsToContent()
        self.totalContentNum = progressionsTuple.totalNumber
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

    progressionsService.progressions(parameters: defaultParameters) { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "ProgressionsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let progressionsTuple):
        self.data = progressionsTuple.progressions.compactMap { $0.content }
        self.addRelevantDetailsToContent()
        self.totalContentNum = progressionsTuple.totalNumber
        self.state = .hasData
      }
    }
  }
  
  private func addRelevantDetailsToContent() {
    
    data.forEach { model in
      guard let dataManager = DataManager.current, model.contentType != .episode else { return }
      var relationships: [ContentRelatable] = []
      let domains = dataManager.domainsMC.data.filter { model.domainIDs.contains($0.id) }
      relationships.append(contentsOf: domains)
      
      model.addRelationships(for: relationships)
    }
  }
}

extension ProgressionsContentVM: ContentUpdatable {
  func updateEntryIfItExists(for content: ContentDetailsModel) {
    guard let index = data.firstIndex(where: { $0.id == content.id } ) else { return }
    
    data[index] = content
    state = .hasData
  }
}
