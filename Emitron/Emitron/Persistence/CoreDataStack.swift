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

import CoreData
import Foundation

/// Setup the **CoreDataStack** for the application using **NSPersistentContainer**
final class CoreDataStack {

  // MARK: - Properties

  /// The name for the data model to be used by the core data stack
  private let modelName: String

  /// Type of persistent store to setup the core data stack to use i.e. XML, Memory, SQLite etc...
  ///
  /// - note: leaving this **nil** will default to the **NSSQLiteStoreType** value
  private let persistentStoreType: String?

  /// **NSManagedObjectContext** of concurrency type **mainQueueConcurrencyType**
  var viewContext: NSManagedObjectContext {
    return self.storeContainer.viewContext
  }

  /// Setup a new background context to be used by the application
  var backgroundContext: NSManagedObjectContext {
    let context = storeContainer.newBackgroundContext()
    context.mergePolicy = NSMergePolicy.overwrite
    return context
  }

  /// Persistent store container for your persistence stack
  private var storeContainer: NSPersistentContainer!

  // MARK: - Initializers
  init(modelName: String = "Emitron",
       persistentStoreType: String? = nil) {
    self.modelName = modelName
    self.persistentStoreType = persistentStoreType
  }
}

// MARK: - Internal
extension CoreDataStack {

  /// Setup the backing **NSPersistentContainer** for this stack
  func setupPersistentContainer() {
    let container = NSPersistentContainer(name: modelName)

    // If provided set the persistent store description to the provided persistent store type, mostly for tests
    if let persistentStoreType = persistentStoreType {
      let description = NSPersistentStoreDescription()
      description.type = persistentStoreType
      container.persistentStoreDescriptions = [description]
    }

    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    container.viewContext.automaticallyMergesChangesFromParent = true

    self.storeContainer = container
  }

  /// Perform a background task on the application using new api from the **NSPersistentContainer**
  ///
  /// - parameters:
  ///   - block: block of code to be run in the background context
  func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
    self.storeContainer.performBackgroundTask { context in
      context.mergePolicy = NSMergePolicy.overwrite
      block(context)
    }
  }

  /// Saves a background task context within the application
  ///
  /// - note: this method should only ever be called within the **performBackgroundTask** block
  ///         on the iOS10 **NSPersistentContainer** and hence the reason it does not do a **perform**
  ///         on the passed in context since it should already be on that context
  ///
  /// - parameters:
  ///   - context: background task **NSManagedObjectContext** to be saved
  func saveBackgroundTask(_ context: NSManagedObjectContext) {
    let contextSaveBlock = generateContextSaveBlock(context: context)
    contextSaveBlock()
  }

  /// Saves the background context in the application
  ///
  /// - note: no parent contexts will be saved since the **NSPersistenceContainer** will take care of doing everything for us
  ///         If you call with **async** false then the method makes the assumption you're already on the context's thread so
  ///         make sure you are on the thread before calling
  ///
  /// - parameters:
  ///   - context: background **NSManagedObjectContext** to be saved
  ///   - async: **true** will use the context perform to save
  ///            **false** will use the context perform and wait to save
  ///   - completion: will be called once the save has successfully occurred on the context or if the context did not have changes
  func saveBackground(_ context: NSManagedObjectContext,
                      async: Bool = true,
                      completion: @escaping () -> Void = {}) {
    let contextSaveBlock = generateContextSaveBlock(context: context,
                                                    completion: completion)
    if async {
      context.perform(contextSaveBlock)
    } else {
      contextSaveBlock()
    }
  }

  /// Save the provided **NSManagedObjectContext** without waiting for the results
  ///
  /// - warning: you must call this method on the context thread you're saving since it does not do the perform block
  ///            since the new background context's should be saving data into the context.
  ///
  /// - parameters:
  ///   - context: **NSManagedObjectContext** to be saved
  ///   - completion: will be called once the initial save has occurred and the next save
  ///                 has been queued in the system to avoid issues where the app is
  ///                 waiting for the save to occur before continuing with its work
  func saveUsingContext(_ context: NSManagedObjectContext,
                        completion: @escaping () -> Void = {}) {
    let contextSaveBlock = generateContextSaveBlock(context: context,
                                                    completion: completion)
    contextSaveBlock()
  }
}

// MARK: - Private
private extension CoreDataStack {

  /// Generate the context save block to be utilized by the stack
  ///
  /// - parameters:
  ///   - context: the managed object context to be saved
  ///
  /// - returns: block of code to be executed
  func generateContextSaveBlock(context: NSManagedObjectContext,
                                completion: @escaping () -> Void = {}) -> () -> Void {
    return { [weak self] in
      guard let self = self,
        context.hasChanges else {
          completion()
          return
      }

      // Generally means the coordinator was being reset and hence should just call completion
      // The persistent store coordinators either have to match and the context cannot have a
      // **nil** persistent store coordinator in order to allow saving the information
      if context.persistentStoreCoordinator == nil ||
        self.storeContainer.persistentStoreCoordinator != context.persistentStoreCoordinator {
        completion()
        return
      }

      do {
        try context.save()
        completion()
      } catch let error as NSError {
        fatalError("Could not save background context asynchronously: \(error)")
      }
    }
  }
}
