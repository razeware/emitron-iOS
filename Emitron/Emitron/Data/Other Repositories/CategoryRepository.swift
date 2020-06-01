// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine

class CategoryRepository: Refreshable {
  let repository: Repository
  let service: CategoriesService

  var refreshableCheckTimeSpan: RefreshableTimeSpan = .long
  
  @Published private (set) var state: DataState = .initial
  @Published private (set) var categories: [Category] = []
  
  init(repository: Repository, service: CategoriesService) {
    self.repository = repository
    self.service = service
    populate()
  }
  
  func populate() {
    loadFromPersistentStore()
    
    if shouldRefresh || categories.isEmpty {
      fetchCategoriesAndUpdatePersistentStore()
    }
  }
  
  private func loadFromPersistentStore() {
    do {
      self.categories = try repository.categoryList()
      state = .hasData
    } catch {
      self.state = .failed
      Failure
        .fetch(from: "CategoryRepository", reason: error.localizedDescription)
        .log()
    }
  }
  
  private func saveToPersistentStore() {
    do {
      try self.repository.syncCategoryList(self.categories)
    } catch {
      Failure
        .fetch(from: "CategoryRepository", reason: error.localizedDescription)
        .log()
    }
  }
  
  private func fetchCategoriesAndUpdatePersistentStore() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    state = .loading
    
    service.allCategories { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
        .fetch(from: "CategoryRepository", reason: error.localizedDescription)
        .log()
      case .success(let categories):
        self.categories = categories
        self.state = .hasData
        self.saveToPersistentStore()
        self.saveOrReplaceRefreshableUpdateDate()
      }
    }
  }
}
