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

import XCTest
@testable import Emitron
import CoreData

class DownloadTest: XCTestCase {
  private var coreDataStack: CoreDataStack!
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    coreDataStack = CoreDataStack(modelName: "Emitron", persistentStoreType: NSInMemoryStoreType)
    coreDataStack.setupPersistentContainer()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  var coreDataContext: NSManagedObjectContext {
    coreDataStack.viewContext
  }
  
  func getAllContents() -> [Contents] {
    try! coreDataContext.fetch(Contents.fetchRequest())
  }
  
  func getAllDownloads() -> [Download] {
    try! coreDataContext.fetch(Download.fetchRequest())
  }
  
  func testDeletingDownloadDoesNotDeleteContents() {
    let contents = CoreDataMocks.contents(context: coreDataContext)
    let download = CoreDataMocks.download(context: coreDataContext)
    download.content = contents
    try! coreDataContext.save()
    
    // Delete the download
    coreDataContext.delete(download)
    try! coreDataContext.save()
    
    // Check it was deleted
    XCTAssertEqual(0, getAllDownloads().count)
    // And that the contents was not deleted
    XCTAssertEqual(1, getAllContents().count)
    XCTAssertEqual(contents, getAllContents().first!)
  }
  
  func testCannotCreateDownloadWithoutContents() {
    let _ = CoreDataMocks.download(context: coreDataContext)
    XCTAssertThrowsError(try coreDataContext.save())
  }
  
  func testStatePropertyRespectsBackingVariable() {
    let contents = CoreDataMocks.contents(context: coreDataContext)
    let download = CoreDataMocks.download(context: coreDataContext)
    download.content = contents
    try! coreDataContext.save()
    
    // Set the state int
    download.stateInt = 4
    try! coreDataContext.save()
    
    // Check that state matches
    XCTAssertEqual(Download.State.paused, download.state)
  }
  
  func testStatePropertyCorrectlySetsBackingVariable() {
    let contents = CoreDataMocks.contents(context: coreDataContext)
    let download = CoreDataMocks.download(context: coreDataContext)
    download.content = contents
    try! coreDataContext.save()
    
    // Set the state
    download.state = .inProgress
    try! coreDataContext.save()
    
    // Check that state matches
    XCTAssertEqual(3, download.stateInt)
  }
  
  func testInvalidStateBackingVariableWorksAsExpected() {
    let contents = CoreDataMocks.contents(context: coreDataContext)
    let download = CoreDataMocks.download(context: coreDataContext)
    download.content = contents
    try! coreDataContext.save()
    
    // Set the state int
    download.stateInt = 100
    try! coreDataContext.save()
    
    // Check that state is read as pending
    XCTAssertEqual(Download.State.pending, download.state)
  }
}
