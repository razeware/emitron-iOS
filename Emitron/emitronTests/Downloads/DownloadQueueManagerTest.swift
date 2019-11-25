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
import CoreData
import Combine
@testable import Emitron

class DownloadQueueManagerTest: XCTestCase {
  
  private var coreDataStack: CoreDataStack!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var queueManager: DownloadQueueManager!
  private var subscriptions = Set<AnyCancellable>()
  
  override func setUp() {
    coreDataStack = CoreDataStack(modelName: "Emitron", persistentStoreType: NSInMemoryStoreType)
    coreDataStack.setupPersistentContainer()
    downloadService = DownloadService(coreDataStack: coreDataStack, videosService: videoService)
    queueManager = DownloadQueueManager(coreDataStack: coreDataStack)
  }
  
  override func tearDown() {
    videoService.reset()
    subscriptions = []
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
  
  func sampleDownload() -> Download {
    let screencast = ContentDetailsModelTest.Mocks.screencast
    downloadService.requestDownload(content: screencast)
    return getAllDownloads().first!
  }
  
  func sampleCDDownload(state: Download.State = .pending) -> Download {
    let content = CoreDataMocks.contents(context: coreDataContext)
    let download = CoreDataMocks.download(context: coreDataContext)
    download.state = state
    content.download = download
    
    try! coreDataContext.save()
    
    return download
  }
  
  func testPendingStreamSendsNewDownloads() {
    var received = [Download]()
    queueManager.pendingStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0) })
      .store(in: &subscriptions)
    
    let download = sampleDownload()
    download.state = .urlRequested
    
    try! coreDataContext.save()
    
    XCTAssertEqual([download], received)
  }
  
  func testPendingStreamSendingPreExistingDownloads() {
    var received = [Download]()
    
    let download = sampleDownload()
    
    queueManager.pendingStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0) })
      .store(in: &subscriptions)
    
    XCTAssertEqual([download], received)
  }
  
  func testDownloadQueueStreamRespectsTheMaxLimit() {
    var received = [Download]()
    
    queueManager.downloadQueueStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0) })
      .store(in: &subscriptions)
    
    let download1 = sampleCDDownload(state: .enqueued)
    let download2 = sampleCDDownload(state: .enqueued)
    let _ = sampleCDDownload(state: .enqueued)
    
    XCTAssertEqual([download1, download2], received)
  }
  
  func testDownloadQueueStreamSendsFromThePast() {
    var received = [Download]()
    let download1 = sampleCDDownload(state: .enqueued)
    let download2 = sampleCDDownload(state: .enqueued)
    let _ = sampleCDDownload(state: .enqueued)
    
    queueManager.downloadQueueStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0) })
      .store(in: &subscriptions)
    
    XCTAssertEqual([download1, download2], received)
  }
  
  func testDownloadQueueStreamSendsInProgressFirst() {
    
  }
  
  func testDownloadQueueStreamUpdatesWhenInProgressCompleted() {
    
  }
  
  func testDownloadQueueStreamDoesNotChangeIfAtCapacity() {
    var received = [Download]()
    let download1 = sampleCDDownload(state: .enqueued)
    let download2 = sampleCDDownload(state: .enqueued)
    
    queueManager.downloadQueueStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0) })
      .store(in: &subscriptions)
    
    let _ = sampleCDDownload(state: .enqueued)
    
    XCTAssertEqual([download1, download2], received)
  }
  
}
