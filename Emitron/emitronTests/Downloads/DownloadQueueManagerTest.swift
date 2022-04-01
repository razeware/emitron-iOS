// Copyright (c) 2022 Razeware LLC
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

import XCTest
import GRDB
import Combine
@testable import Emitron

final class DownloadQueueManagerTest: XCTestCase, DatabaseTestCase {
  private(set) var database: TestDatabase!
  private var persistenceStore: PersistenceStore!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var queueManager: DownloadQueueManager!
  private var settingsManager: SettingsManager!

  override func setUpWithError() throws {
    try super.setUpWithError()

    // There's one already running—let's stop that
    if downloadService != nil {
      downloadService.stopProcessing()
    }

    database = try EmitronDatabase.test
    persistenceStore = PersistenceStore(db: database)
    settingsManager = App.objects.settingsManager
    let userModelController = UserMCMock(user: .withDownloads)
    downloadService = DownloadService(persistenceStore: persistenceStore, userModelController: userModelController, videosServiceProvider: { _ in self.videoService }, settingsManager: settingsManager)

    queueManager = DownloadQueueManager(persistenceStore: persistenceStore)
    downloadService.stopProcessing()
  }
  
  override func tearDown() {
    super.tearDown()
    videoService.reset()
  }
  
  func sampleDownload() async throws -> Download {
    let screencast = ContentTest.Mocks.screencast
    let result = try await downloadService.requestDownload(contentID: screencast.0.id) { _ in
        .init(content: screencast.0, cacheUpdate: screencast.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    return try XCTUnwrap(allDownloads.first)
  }
  
  @discardableResult func samplePersistedDownload(state: Download.State = .pending) throws -> Download {
    try database.write { db in
      let content = PersistenceMocks.content
      try content.save(db)
      
      var download = PersistenceMocks.download(for: content)
      download.state = state
      try download.save(db)
      
      return download
    }
  }
  
  func testPendingStreamSendsNewDownloads() async throws {
    let recorder = queueManager.pendingStream.record()
    
    var download = try await sampleDownload()
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    let downloads = try wait(for: recorder.next(2), timeout: 10, description: "PendingDownloads")
    
    XCTAssertEqual([nil, download], downloads.map { $0?.download })
  }
  
  func testPendingStreamSendingPreExistingDownloads() async throws {
    var download = try await sampleDownload()
    download = try await database.write { [download] db in
      try download.saved(db)
    }

    let pending = try wait(for: queueManager.pendingStream.record().next(), timeout: 10)
    XCTAssertEqual(download, pending!.download)
  }
  
  func testReadyForDownloadStreamSendsUpdatesAsListChanges() throws {
    var download1 = try samplePersistedDownload(state: .readyForDownload)
    var download2 = try samplePersistedDownload(state: .readyForDownload)
    var download3 = try samplePersistedDownload(state: .urlRequested)
    
    let recorder = queueManager.readyForDownloadStream.record()
    var readyForDownload = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual(download1, readyForDownload!.download)
    
    try database.write { db in
      download3.state = .readyForDownload
      try download3.save(db)
    }
    
    // This shouldn't fire cos it doesn't affect the stream
    // readyForDownload = try wait(for: recorder.next(), timeout: 10)
    // XCTAssertEqual(download1, readyForDownload!!.download)
    
    try database.write { db in
      download1.state = .enqueued
      try download1.save(db)
    }
    readyForDownload = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual(download2, readyForDownload!.download)
    
    try database.write { db in
      download2.state = .enqueued
      try download2.save(db)
    }
    readyForDownload = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual(download3, readyForDownload!.download)
    
    try database.write { db in
      download3.state = .enqueued
      try download3.save(db)
    }
    readyForDownload = try wait(for: recorder.next(), timeout: 10)
    XCTAssertNil(readyForDownload)
  }
  
  func testDownloadQueueStreamRespectsTheMaxLimit() throws {
    let recorder = queueManager.downloadQueue.record()
    
    let download1 = try samplePersistedDownload(state: .enqueued)
    let download2 = try samplePersistedDownload(state: .enqueued)
    _ = try samplePersistedDownload(state: .enqueued)
    
    let queue = try wait(for: recorder.next(4), timeout: 30)
    XCTAssertEqual(
      [ [],                     // Empty to start
        [download1],            // d1 Enqueued
        [download1, download2], // d2 Enqueued
        [download1, download2]  // Final download makes no difference
      ],
      queue.map { $0.map(\.download) }
    )
  }
  
  func testDownloadQueueStreamSendsFromThePast() throws {
    let download1 = try samplePersistedDownload(state: .enqueued)
    let download2 = try samplePersistedDownload(state: .enqueued)
    try samplePersistedDownload(state: .enqueued)
    
    let recorder = queueManager.downloadQueue.record()
    let queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download1, download2], queue.map(\.download))
  }
  
  func testDownloadQueueStreamSendsInProgressFirst() throws {
    try samplePersistedDownload(state: .enqueued)
    let download2 = try samplePersistedDownload(state: .inProgress)
    try samplePersistedDownload(state: .enqueued)
    let download4 = try samplePersistedDownload(state: .inProgress)
    
    let recorder = queueManager.downloadQueue.record()
    let queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download2, download4], queue.map(\.download))
  }
  
  func testDownloadQueueStreamUpdatesWhenInProgressCompleted() throws {
    let download1 = try samplePersistedDownload(state: .enqueued)
    var download2 = try samplePersistedDownload(state: .inProgress)
    try samplePersistedDownload(state: .enqueued)
    let download4 = try samplePersistedDownload(state: .inProgress)
    
    let recorder = queueManager.downloadQueue.record()
    var queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download2, download4], queue.map(\.download))
    
    try database.write { db in
      download2.state = .complete
      try download2.save(db)
    }
    
    queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download4, download1], queue.map(\.download))
  }
  
  func testDownloadQueueStreamDoesNotChangeIfAtCapacity() throws {
    let download1 = try samplePersistedDownload(state: .enqueued)
    let download2 = try samplePersistedDownload(state: .enqueued)
    
    let recorder = queueManager.downloadQueue.record()
    var queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download1, download2], queue.map(\.download))
    
    try samplePersistedDownload(state: .enqueued)
    queue = try wait(for: recorder.next(), timeout: 10)
    XCTAssertEqual([download1, download2], queue.map(\.download))
  }
}
