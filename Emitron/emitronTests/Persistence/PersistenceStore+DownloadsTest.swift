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
@testable import Emitron

class PersistenceStore_DownloadsTest: XCTestCase, DatabaseTestCase {
  private(set) var database: TestDatabase!
  private var persistenceStore: PersistenceStore!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try EmitronDatabase.test
    persistenceStore = .init(db: database)
    
    // Check it's all empty
    XCTAssert(try allContents.isEmpty)
    XCTAssert(try allDownloads.isEmpty)
  }
  
  func populateSampleScreencast() async throws -> Content {
    let screencast = ContentTest.Mocks.screencast
    let fullState = ContentPersistableState(content: screencast.0, cacheUpdate: screencast.1)
    try await persistenceStore.persistContentGraph(for: fullState) { contentID in
      .init(contentID: contentID, cacheUpdate: screencast.1)
    }
    
    return screencast.0
  }
  
  func populateSampleCollection() async throws -> Content {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    try await persistenceStore.persistContentGraph(for: fullState) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }
    return collection.0
  }
  
  // MARK: - Download Transitions
  func testTransitionEpisodeToInProgressUpdatesCollection() async throws {
    let collection = try await populateSampleCollection()
    let episode = try allContents.first { $0.id != collection.id }
    
    var collectionDownload = PersistenceMocks.download(for: collection)
    var episodeDownload = PersistenceMocks.download(for: episode!)
    
    (collectionDownload, episodeDownload) = try await database.write { [collectionDownload, episodeDownload] db in
      try (collectionDownload.saved(db), episodeDownload.saved(db))
    }
    
    try await persistenceStore.transitionDownload(withID: episodeDownload.id, to: .inProgress)

    let updatedCollectionDownload = try await database.read { [key = collectionDownload.id] db in
      try Download.filter(key: key).fetchOne(db)
    }.unwrapped
    XCTAssertEqual(updatedCollectionDownload.state, .inProgress)
    XCTAssertEqual(updatedCollectionDownload.progress, 0)
  }
  
  func testTransitionEpisodeToDownloadedUpdatesCollection() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    var collectionDownload = PersistenceMocks.download(for: collection)
    var episodeDownload = PersistenceMocks.download(for: episodes[0])
    var episodeDownload2 = PersistenceMocks.download(for: episodes[1])

    (collectionDownload, episodeDownload, episodeDownload2) = try await database.write {
      [collectionDownload, episodeDownload, episodeDownload2] db in
      try (collectionDownload.saved(db), episodeDownload.saved(db), episodeDownload2.saved(db))
    }
    
    try await persistenceStore.transitionDownload(withID: episodeDownload.id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownload2.id, to: .complete)

    let updatedCollectionDownload = try await database.read { [key = collectionDownload.id] db in
      try Download.filter(key: key).fetchOne(db)
    }.unwrapped
    XCTAssertEqual(.inProgress, updatedCollectionDownload.state)
    XCTAssertEqual(0.5, updatedCollectionDownload.progress)
  }
  
  func testTransitionFinalEpisodeToDownloadedUpdatesCollection() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    var collectionDownload = PersistenceMocks.download(for: collection)
    let episodeDownloads = episodes.map(PersistenceMocks.download)
    
    collectionDownload = try await database.write { [collectionDownload] db in
      try collectionDownload.saved(db)
    }
    
    try await database.write { db in
      try episodeDownloads.forEach { download in
        var mutableDownload = download
        try mutableDownload.save(db)
      }
    }

    for episode in episodeDownloads {
      try await persistenceStore.transitionDownload(withID: episode.id, to: .complete)
    }

    let updatedCollectionDownload = try await database.read { [key = collectionDownload.id] db in
      try Download.filter(key: key).fetchOne(db)
    }.unwrapped

    XCTAssertEqual(updatedCollectionDownload.state, .complete)
    XCTAssertEqual(updatedCollectionDownload.progress, 1)
  }
  
  func testTransitionNonFinalEpisodeToDownloadedUpdatesCollection() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    var collectionDownload = PersistenceMocks.download(for: collection)
    var episodeDownload = PersistenceMocks.download(for: episodes[0])
    var episodeDownload2 = PersistenceMocks.download(for: episodes[1])

    (collectionDownload, episodeDownload, episodeDownload2) = try await database.write { [collectionDownload, episodeDownload, episodeDownload2] db in
      try (collectionDownload.saved(db), episodeDownload.saved(db), episodeDownload2.saved(db))
    }
    
    try await persistenceStore.transitionDownload(withID: episodeDownload.id, to: .complete)
    try await persistenceStore.transitionDownload(withID: episodeDownload2.id, to: .complete)

    let updatedCollectionDownload = try await database.read { [key = collectionDownload.id] db in
      try Download.filter(key: key).fetchOne(db)
    }.unwrapped

    XCTAssertEqual(updatedCollectionDownload.state, .paused)
    XCTAssertEqual(updatedCollectionDownload.progress, 1)
  }
  
  // MARK: - Collection Download Utilities
  func testCollectionDownloadSummaryWorksForInProgress() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }

    let episodeDownloads = episodes.map(PersistenceMocks.download)
    
    try await database.write { db in
      try episodeDownloads.forEach { download in
        var mutableDownload = download
        try mutableDownload.save(db)
      }
    }

    for episodeDownload in episodeDownloads[0..<5] {
      try await persistenceStore.transitionDownload(withID: episodeDownload.id, to: .complete)
    }
    
    let summary = try await persistenceStore.collectionDownloadSummary(forContentID: collection.id)
    XCTAssertEqual(
      summary,
      .init(
        totalChildren: episodes.count,
        childrenRequested: episodes.count,
        childrenCompleted: 5
      )
    )
  }
  
  func testCollectionDownloadSummaryWorksForPartialRequest() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    PersistenceMocks.download(for: collection)
    let episodeDownloads = episodes[0..<10].map(PersistenceMocks.download)
    
    try await database.write { db in
      try episodeDownloads.forEach { download in
        var mutableDownload = download
        try mutableDownload.save(db)
      }
    }
    
    for episodeDownload in episodeDownloads[0..<5] {
      try await persistenceStore.transitionDownload(
        withID: episodeDownload.id,
        to: .complete
      )
    }

    let summary = try await persistenceStore.collectionDownloadSummary(forContentID: collection.id)
    XCTAssertEqual(
      summary,
      .init(
        totalChildren: episodes.count,
        childrenRequested: 10,
        childrenCompleted: 5
      )
    )
  }
  
  func testCollectionDownloadSummaryWorksForCompletedPartialRequest() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    PersistenceMocks.download(for: collection)
    let episodeDownloads = episodes[0..<10].map(PersistenceMocks.download)
    
    try await database.write { db in
      try episodeDownloads.forEach { download in
        var mutableDownload = download
        try mutableDownload.save(db)
      }
    }
    
    for episodeDownload in episodeDownloads {
      try await persistenceStore.transitionDownload(
        withID: episodeDownload.id,
        to: .complete
      )
    }

    let summary = try await persistenceStore.collectionDownloadSummary(forContentID: collection.id)
    XCTAssertEqual(
      summary,
      .init(
        totalChildren: episodes.count,
        childrenRequested: 10,
        childrenCompleted: 10
      )
    )
  }
  
  func testCollectionDownloadSummaryWorksForCompletedEntireRequest() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    PersistenceMocks.download(for: collection)
    let episodeDownloads = episodes.map(PersistenceMocks.download)
    
    try await database.write { db in
      try episodeDownloads.forEach { download in
        var mutableDownload = download
        try mutableDownload.save(db)
      }
    }
    
    for episodeDownload in episodeDownloads {
      try await persistenceStore.transitionDownload(
        withID: episodeDownload.id,
        to: .complete
      )
    }

    let summary = try await persistenceStore.collectionDownloadSummary(forContentID: collection.id)
    XCTAssertEqual(
      summary,
      .init(
        totalChildren: episodes.count,
        childrenRequested: episodes.count,
        childrenCompleted: episodes.count
      )
    )
  }
  
  func testCollectionDownloadSummaryThrowsForNonCollection() async throws {
    let screencast = try await populateSampleScreencast()
    
    var download = PersistenceMocks.download(for: screencast)
    download = try await database.write { [download] db in
      try download.saved(db)
    }

    do {
      _ = try await persistenceStore.collectionDownloadSummary(forContentID: screencast.id)
      XCTFail()
    } catch {
      guard case PersistenceStoreError.argumentError = error
      else { XCTFail(); return }
    }
  }
  
  // MARK: - Creating Downloads
  private func createDownloads(for content: Content) async throws {
    try await persistenceStore.createDownloads(for: content)
  }
  
  func testCreateDownloadsCreatesSingleDownloadForScreencast() async throws {
    let screencast = try await populateSampleScreencast()
    XCTAssert(try allDownloads.isEmpty)
    try await createDownloads(for: screencast)
    XCTAssertEqual(1, try allDownloads.count)
  }
  
  func testCreateDownloadsCreatesTwoDownloadsForEpisode() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    XCTAssert(try allDownloads.isEmpty)
    try await createDownloads(for: XCTUnwrap(episodes.first))
    XCTAssertEqual(2, try allDownloads.count)
  }
  
  func testCreateDownloadsCreatesOneAdditionalDownloadForEpisodeInPartiallyDownloadedCollection() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    XCTAssert(try allDownloads.isEmpty)
    try await createDownloads(for: XCTUnwrap(episodes.first))
    XCTAssertEqual(2, try allDownloads.count)
    try await createDownloads(for: episodes[2])
    XCTAssertEqual(3, try allDownloads.count)
  }
  
  func testCreateDownloadsForExistingDownloadMakesNoChange() async throws {
    let collection = try await populateSampleCollection()
    let episodes = try allContents.filter { $0.id != collection.id }
    
    XCTAssert(try allDownloads.isEmpty)
    let episode = try XCTUnwrap(episodes.first)
    try await createDownloads(for: episode)
    XCTAssertEqual(try allDownloads.count, 2)
    try await createDownloads(for: episode)
    XCTAssertEqual(try allDownloads.count, 2)
  }
  
  func testCreateDownloadsForCollectionCreateManyDownloads() async throws {
    let collection = try await populateSampleCollection()
    
    XCTAssert(try allDownloads.isEmpty)
    
    try await createDownloads(for: collection)
    
    XCTAssertEqual(try allContents.count, try allDownloads.count)
    XCTAssertFalse(try allContents.isEmpty)
  }
  
  // MARK: - Queue management
  func testDownloadListDoesNotContainEpisodes() async throws {
    let collection = try await populateSampleCollection()
    try await createDownloads(for: collection)
    
    let recorder = persistenceStore.downloadList().record()
    
    let list = try wait(for: recorder.next(), timeout: 10)
    
    XCTAssertNotNil(list)
    
    XCTAssertEqual(1, list.count)
    XCTAssert(list.filter { $0.contentType == .episode }.isEmpty)
  }
  
  func testDownloadsInStateDoesNotContainCollections() async throws {
    let collection = try await populateSampleCollection()
    try await createDownloads(for: collection)
    
    let recorder = persistenceStore.downloads(in: .inProgress).record()
    
    let downloads = try allDownloads.sorted { $0.requestedAt < $1.requestedAt }
    let episodes = try allContents.filter { $0.contentType == .episode }
    for download in downloads {
      try await persistenceStore.transitionDownload(withID: download.id, to: .inProgress)
    }
    
    for download in downloads {
      try await persistenceStore.transitionDownload(withID: download.id, to: .complete)
    }
    
    // Will start with a nil
    let inProgressQueue = try wait(for: recorder.next(episodes.count + 1), timeout: 10)
    
    XCTAssert(inProgressQueue.filter { $0?.content.contentType == .collection }.isEmpty)
    XCTAssertEqual(
      episodes.map(\.id).sorted(),
      inProgressQueue.compactMap { $0?.content.id }.sorted()
    )
  }
  
  func testDownloadQueueDoesNotContainCollections() async throws {
    let collection = try await populateSampleCollection()
    try await createDownloads(for: collection)
    
    let recorder = persistenceStore.downloadQueue(withMaxLength: 4).record()
    
    let episodes = try allContents.filter({ $0.contentType == .episode })
    let episodeIDs = episodes.map(\.id)
    let collectionDownload = try allDownloads.first { !episodeIDs.contains($0.contentID) }
    let episodeDownloads = try allDownloads.filter { episodeIDs.contains($0.contentID) }
    
    try await persistenceStore.transitionDownload(withID: episodeDownloads[1].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: collectionDownload!.id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[0].id, to: .inProgress)
    
    let downloadQueue = try wait(for: recorder.next(3), timeout: 10)
    
    XCTAssertEqual(3, downloadQueue.count)
    XCTAssertEqual([], downloadQueue[0])
    XCTAssertEqual([episodeDownloads[1].id], downloadQueue[1].map(\.download.id))
    XCTAssertEqual([episodeDownloads[0].id, episodeDownloads[1].id], downloadQueue[2].map(\.download.id))
  }
  
  func testDownloadQueueReturnsCorrectNumberOfItems() async throws {
    let collection = try await populateSampleCollection()
    try await createDownloads(for: collection)
    
    let recorder = persistenceStore.downloadQueue(withMaxLength: 4).record()
    
    let episodes = try allContents.filter({ $0.contentType == .episode })
    let episodeIDs = episodes.map(\.id)
    let collectionDownload = try allDownloads.first { !episodeIDs.contains($0.contentID) }
    let episodeDownloads = try allDownloads.filter { episodeIDs.contains($0.contentID) }
    
    try await persistenceStore.transitionDownload(withID: episodeDownloads[1].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: collectionDownload!.id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[0].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[5].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[4].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[3].id, to: .inProgress)
    try await persistenceStore.transitionDownload(withID: episodeDownloads[2].id, to: .inProgress)
    
    let downloadQueue = try wait(for: recorder.next(7), timeout: 10)
    
    XCTAssertEqual(7, downloadQueue.count)
    XCTAssertEqual([], downloadQueue[0])
    XCTAssertEqual([1].map { episodeDownloads[$0].id }, downloadQueue[1].map(\.download.id))
    XCTAssertEqual([0, 1].map { episodeDownloads[$0].id }, downloadQueue[2].map(\.download.id))
    XCTAssertEqual([0, 1, 5].map { episodeDownloads[$0].id }, downloadQueue[3].map(\.download.id))
    XCTAssertEqual([0, 1, 4, 5].map { episodeDownloads[$0].id }, downloadQueue[4].map(\.download.id))
    XCTAssertEqual([0, 1, 3, 4].map { episodeDownloads[$0].id }, downloadQueue[5].map(\.download.id))
    XCTAssertEqual([0, 1, 2, 3].map { episodeDownloads[$0].id }, downloadQueue[6].map(\.download.id))
  }
  
  func testDownloadWithIDReturnsCorrectDownload() async throws {
    let screencast = try await populateSampleScreencast()
    
    var download = PersistenceMocks.download(for: screencast)
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    XCTAssertEqual(download, try persistenceStore.download(withID: download.id))
  }
  
  func testDownloadWithIDReturnsNilForNoDownload() throws {
    XCTAssertNil(try persistenceStore.download(withID: UUID()))
  }
  
  func testDownloadForContentIDReturnsCorrectDownload() async throws {
    let screencast = try await populateSampleScreencast()
    
    var download = PersistenceMocks.download(for: screencast)
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    XCTAssertEqual(download, try persistenceStore.download(forContentID: screencast.id))
  }
  
  func testDownloadForContentIDReturnsNilForNoDownload() async throws {
    let screencast = try await populateSampleScreencast()
    
    XCTAssertNil(try persistenceStore.download(forContentID: screencast.id))
  }
  
  func testDownloadForContentIDReturnsNilForNoContent() throws {
    XCTAssertNil(try persistenceStore.download(forContentID: 1234))
  }
}
