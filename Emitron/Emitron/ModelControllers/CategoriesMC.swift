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

class CategoriesMC: ObservableObject, Refreshable {
  
  var refreshableUserDefaultsKey: String = "UserDefaultsRefreshable\(String(describing: CategoriesMC.self))"
  var refreshableCheckTimeSpan: RefreshableTimeSpan = .long
  
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }
  
  private let client: RWAPI
  private let user: UserModel
  private let service: CategoriesService
  private(set) var data: [CategoryModel] = []
  private let persistenceStore: PersistenceStore
  
  // MARK: - Initializers
  init(user: UserModel,
       persistenceStore: PersistenceStore) {
    self.user = user
    self.client = RWAPI(authToken: user.token)
    self.service = CategoriesService(client: self.client)
    self.persistenceStore = persistenceStore    
  }
  
  func populate() {
    // TODO: Add a timing refresh function
    
    loadFromPersistentStore()
    
    if shouldRefresh {
      fetchCategories()
      saveOrReplaceRefreshableUpdateDate()
    }
  }
}

// MARK: - Private
private extension CategoriesMC {
  
  func loadFromPersistentStore() {
    
    do {
      let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
      let result = try persistenceStore.coreDataStack.viewContext.fetch(fetchRequest)
      let categoryModels = result.map(CategoryModel.init)
      data = categoryModels
      state = .hasData
    } catch {
      Failure
        .loadFromPersistentStore(from: "CategoriesMC", reason: "Failed to load entities from core data.")
        .log(additionalParams: nil)
      data = []
      state = .failed
    }
  }
  
  func saveToPersistentStore() {
    let viewContext = persistenceStore.coreDataStack.viewContext    
    for entry in data {
      let category = Category(context: viewContext)

      category.id = NSNumber(value: entry.id)
      category.name = entry.name
      category.uri = entry.uri
      category.ordinal = NSNumber(value: entry.ordinal)
    }
    
    // Delete old records first
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
      try viewContext.execute(deleteRequest)
    } catch {
      Failure
        .deleteFromPersistentStore(from: "CategoriesMC", reason: "Failed to delete entities from core data.")
        .log(additionalParams: nil)
    }
    
    do {
      try viewContext.save()
    } catch {
      Failure
        .saveToPersistentStore(from: "CategoriesMC", reason: "Failed to save entities to core data.")
        .log(additionalParams: nil)
    }
    
    saveOrReplaceRefreshableUpdateDate()
  }
  
  func fetchCategories() {
    if case(.loading) = state {
      return
    }

    state = .loading    
    service.allCategories { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "CategoriesMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let categories):
        self.data = categories
        self.state = .hasData
        self.saveToPersistentStore()
      }
    }
  }
}
