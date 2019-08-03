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

class DomainsMC: NSObject, ObservableObject {
  
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    didSet {
      objectWillChange.send(())
    }
  }
  
  private let client: RWAPI
  private let user: UserModel
  private let service: DomainsService
  private(set) var data: [DomainModel] = []
  private let persistentStore: PersistenceStore
  
  // MARK: - Initializers
  init(guardpost: Guardpost, user: UserModel, persistentStore: PersistenceStore) {
    self.user = user
    //TODO: Probably need to handle this better
    self.client = RWAPI(authToken: user.token)
    self.service = DomainsService(client: self.client)
    self.persistentStore = persistentStore
    
    super.init()
    
    loadFromPersistentStore()
  }
  
  func populate() {
    // TODO: Add a timing refresh function
    let timeToUpdate: Bool = true
    
    loadFromPersistentStore()
    
    if timeToUpdate {
      fetchDomains()
    }
  }
  
  private func loadFromPersistentStore() {
    
    do {
      let fetchRequest = Domain().fetchRequest
      let result = try persistentStore.coreDataStack.viewContext.fetch(fetchRequest)
      let domainModels = result.map(DomainModel.init)
      data = domainModels
    } catch {
      Failure
        .loadFromPersistentStore(from: "DomainsMC", reason: "Failed to load entities from core data.")
        .log(additionalParams: nil)
      data = []
    }
  }
  
  private func saveToPersistentStore() {
    let viewContext = persistentStore.coreDataStack.viewContext
    
    guard let domainEntity = NSEntityDescription.entity(forEntityName: "Domain", in: viewContext) else {
      Failure
      .saveToPersistentStore(from: "DomainsMC", reason: "Couldn't create domain entity.")
      .log(additionalParams: nil)
      return
    }
    
    for entry in data {
      let domain = NSManagedObject(entity: domainEntity, insertInto: viewContext)
      domain.setValue(entry.id, forKeyPath: "id")
      domain.setValue(entry.name, forKeyPath: "name")
      domain.setValue(entry.level.rawValue, forKeyPath: "level")
      domain.setValue(entry.slug, forKeyPath: "slug")
      domain.setValue(entry.description, forKeyPath: "desc")
    }
    
    // Delete old records first
    let fetch = Domain().fetchRequest
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch as! NSFetchRequest<NSFetchRequestResult>)
    
    do {
      try viewContext.execute(deleteRequest)
    } catch {
      Failure
        .deleteFromPersistentStore(from: "DomainsMC", reason: "Failed to delete entities from core data.")
        .log(additionalParams: nil)
    }
    
    do {
      try viewContext.save()
    } catch {
      Failure
        .saveToPersistentStore(from: "DomainsMC", reason: "Failed to save entities to core data.")
        .log(additionalParams: nil)
    }
  }
  
  // MARK: - Internal
  private func fetchDomains() {
        
    guard state != .loading else {
      return
    }
    
    state = .loading
    
    service.allDomains { [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "DomainsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let domains):
        self.data = domains
        self.state = .hasData
        self.saveToPersistentStore()
      }
    }
  }
}
