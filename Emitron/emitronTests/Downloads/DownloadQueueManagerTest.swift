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
import GRDB
import Combine
@testable import Emitron

class DownloadQueueManagerTest: XCTestCase {
  private var database: DatabaseWriter!
  private var persistenceStore: PersistenceStore!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var queueManager: DownloadQueueManager!
  private var subscriptions = Set<AnyCancellable>()

  override func setUp() {
    database = try! EmitronDatabase.testDatabase()
    persistenceStore = PersistenceStore(db: database)
    let userModelController = UserMCMock.withDownloads
    downloadService = DownloadService(persistenceStore: persistenceStore,
                                      userModelController: userModelController,
                                      videosServiceProvider: { _ in self.videoService })
    queueManager = DownloadQueueManager(persistenceStore: persistenceStore)
  }
  
  override func tearDown() {
    videoService.reset()
    subscriptions = []
  }
  
  func getAllContents() -> [Content] {
    try! database.read { db in
      try Content.fetchAll(db)
    }
  }
  
  func getAllDownloads() -> [Download] {
    try! database.read { db in
      try Download.fetchAll(db)
    }
  }
  
  func sampleDownload() -> Download {
    let screencast = ContentDetailsModelTest.Mocks.screencast
    downloadService.requestDownload(content: screencast)
    return getAllDownloads().first!
  }
  
  func sampleCDDownload(state: Download.State = .pending) throws -> Download {
    return try database.write { db in
      let content = PersistenceMocks.content
      try content.save(db)
      
      var download = PersistenceMocks.download(for: content)
      download.state = state
      try download.save(db)
      
      return download
    }
  }
  
  func testPendingStreamSendsNewDownloads() throws {
    var received = [Download?]()
    queueManager.pendingStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0?.download) })
      .store(in: &subscriptions)
    
    try database.write { db in
      var download = sampleDownload()
      download.state = .urlRequested
      try download.save(db)
      
      XCTAssertEqual([download], received)
    }

  }
  
  func testPendingStreamSendingPreExistingDownloads() throws {
    var received = [Download?]()
    
    let download = sampleDownload()
    
    queueManager.pendingStream
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0?.download) })
      .store(in: &subscriptions)
    
    XCTAssertEqual([download], received)
  }
  
  func testDownloadQueueStreamRespectsTheMaxLimit() throws {
    var received = [[Download]]()
    
    queueManager.downloadQueue
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0.map { $0.download }) })
      .store(in: &subscriptions)
    
    let download1 = try sampleCDDownload(state: .enqueued)
    let download2 = try sampleCDDownload(state: .enqueued)
    let _ = try sampleCDDownload(state: .enqueued)
    
    XCTAssertEqual([download1, download2], received.last)
  }
  
  func testDownloadQueueStreamSendsFromThePast() throws {
    var received = [[Download]]()
    let download1 = try sampleCDDownload(state: .enqueued)
    let download2 = try sampleCDDownload(state: .enqueued)
    let _ = try sampleCDDownload(state: .enqueued)
    
    queueManager.downloadQueue
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0.map { $0.download }) })
      .store(in: &subscriptions)
    
    XCTAssertEqual(1, received.count)
    XCTAssertEqual([download1, download2], received.first)
  }
  
  func testDownloadQueueStreamSendsInProgressFirst() throws {
    var received = [[Download]]()
    let _ = try sampleCDDownload(state: .enqueued)
    let download2 = try sampleCDDownload(state: .inProgress)
    let _ = try sampleCDDownload(state: .enqueued)
    let download4 = try sampleCDDownload(state: .inProgress)
    
    queueManager.downloadQueue
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0.map { $0.download }) })
      .store(in: &subscriptions)
    
    XCTAssertEqual(1, received.count)
    XCTAssertEqual([download2, download4], received.first)
  }
  
  func testDownloadQueueStreamUpdatesWhenInProgressCompleted() throws {
    var received = [[Download]]()
    let download1 = try sampleCDDownload(state: .enqueued)
    var download2 = try sampleCDDownload(state: .inProgress)
    let _ = try sampleCDDownload(state: .enqueued)
    let download4 = try sampleCDDownload(state: .inProgress)
    
    queueManager.downloadQueue
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0.map { $0.download }) })
      .store(in: &subscriptions)
    
    XCTAssertEqual(1, received.count)
    XCTAssertEqual([download2, download4], received.last)
    
    try database.write { db in
      download2.state = .complete
      try download2.save(db)
    }
    
    XCTAssertEqual(2, received.count)
    XCTAssertEqual([download4, download1], received.last)
  }
  
  func testDownloadQueueStreamDoesNotChangeIfAtCapacity() throws {
    var received = [[Download]]()
    let download1 = try sampleCDDownload(state: .enqueued)
    let download2 = try sampleCDDownload(state: .enqueued)
    
    queueManager.downloadQueue
      .sink(receiveCompletion: { print($0) }, receiveValue: { received.append($0.map { $0.download }) })
      .store(in: &subscriptions)
    
    XCTAssertEqual([[download1, download2]], received)
    
    let _ = try sampleCDDownload(state: .enqueued)
    
    XCTAssertEqual([[download1, download2]], received)
  }
  
}
