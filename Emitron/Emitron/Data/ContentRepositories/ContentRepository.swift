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
import Combine

class ContentRepository<ServiceType, ResponseModelType> {
  let repository: Repository
  let service: ServiceType
  
  private (set) var currentPage: Int = 1
  private (set) var totalContentNum: Int = 0
  
  @Published private (set) var state: DataState = .initial
  @Published private (set) var contents: [ContentSummaryState] = [ContentSummaryState]()
  
  private var contentIds: [Int] = [Int]()
  private var contentSubscription: AnyCancellable?
  
  var nonPaginationParameters = [Parameter]() {
    didSet {
      reload()
    }
  }
  
  // Initialiser
  init(repository: Repository, service: ServiceType) {
    self.repository = repository
    self.service = service
  }
  
  // Method to make service request
  func makeRequest(parameters: [Parameter], completion: @escaping (_ response: Result<([ResponseModelType], DataCacheUpdate, Int), RWAPIError>) -> Void) {
    fatalError("Override this in subclass please")
  }
  
  private (set) var extractContentIds: ([ResponseModelType]) -> ([Int]) = { _ in fatalError("Please provide this in a subclass")}
}

extension ContentRepository: ContentPaginatable {
  func loadMore() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    guard contentIds.isEmpty || contentIds.count <= totalContentNum else {
      return
    }
    
    state = .loadingAdditional
    currentPage += 1
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    let allParams = nonPaginationParameters + [pageParam]
    
    makeRequest(parameters: allParams) { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        self.currentPage -= 1
        self.state = .failed
        Failure
          .fetch(from: String(describing: type(of: self)), reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let (modelObjects, cacheUpdate, totalNumber)):
        self.contentIds += self.extractContentIds(modelObjects)
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalNumber
        self.configureSubscription()
        self.state = .hasData
      }
      
    }
  }
  
  func reload() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    state = .loading
    
    // Reset current page to 1
    currentPage = startingPage
    
    makeRequest(parameters: nonPaginationParameters) {  [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: String(describing: type(of: self)), reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let (modelObjects, cacheUpdate, totalNumber)):
        self.contentIds = self.extractContentIds(modelObjects)
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalNumber
        self.configureSubscription()
        self.state = .hasData
      }
    }
  }
  
  
  private func configureSubscription() {
    self.contentSubscription = self.repository.contentSummaryState(for: self.contentIds).sink(receiveCompletion: { (error) in
      // TODO Logging
      print("Unable to receive content summary update: \(error)")
    }, receiveValue: { (contentSummaryStates) in
      self.contents = contentSummaryStates
    })
  }
}
