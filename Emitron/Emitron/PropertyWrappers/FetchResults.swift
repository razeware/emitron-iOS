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
import CoreData

class FetchResults<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
  private struct NeverError: Error { }
  
  private let resultSubject = PassthroughSubject<T, Error>()
  lazy var resultStream: AnyPublisher<T, Error> = {
    if let results = results {
      let currentResults = results.publisher
        .mapError { _ in NeverError() as Error }
      return self.resultSubject
        .prepend(currentResults)
        .eraseToAnyPublisher()
    }
    return self.resultSubject.eraseToAnyPublisher()
  }()
  var results: [T]? {
    resultsController.fetchedObjects
  }
  
  private let resultsController: NSFetchedResultsController<T>
  
  init(context: NSManagedObjectContext, request: NSFetchRequest<T>) {
    self.resultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    
    super.init()
    
    self.resultsController.delegate = self
    do {
      try self.resultsController.performFetch()
    } catch {
      resultSubject.send(completion: .failure(error))
    }
  }
  
  //: Delegate methods
  // Updates the resultStream property as new results arrive
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    // Gonna send notifications when new items are added
    guard type == .insert else { return }
    guard let object = anObject as? T else { return }
    
    resultSubject.send(object)
  }
}
