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

class DownloadServiceTest: XCTestCase, DatabaseTestCase {
  private(set) var database: TestDatabase!
  private var persistenceStore: PersistenceStore!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var userModelController: UserMCMock!
  private var settingsManager: SettingsManager!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try EmitronDatabase.test
    persistenceStore = PersistenceStore(db: database)
    userModelController = .init(user: .withDownloads)
    settingsManager = App.objects.settingsManager
    downloadService = DownloadService(
      persistenceStore: persistenceStore,
      userModelController: userModelController,
      videosServiceProvider: { [unowned videoService] _ in videoService },
      settingsManager: settingsManager
    )
    
    // Check it's all empty
    XCTAssert(try allContents.isEmpty)
    XCTAssert(try allDownloads.isEmpty)
  }
  
  override func tearDownWithError() throws {
    try super.tearDownWithError()
    videoService.reset()
    try FileManager.removeExistingFile(
      at: .downloadsDirectory.appendingPathComponent("sample_file")
    )
    App.objects.settingsManager.resetAll()
  }
  
  //: requestDownload(content:) Tests
  func testRequestDownloadScreencastAddsContentToLocalStore() async throws {
    let screencast = ContentTest.Mocks.screencast
    let result = try await downloadService.requestDownload(contentID: screencast.0.id) { _ in
      .init(content: screencast.0, cacheUpdate: screencast.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)
    XCTAssertEqual(1, try allContents.count)
    XCTAssertEqual(screencast.0.id, Int(try allContents.first!.id))
  }
  
  func testRequestDownloadScreencastUpdatesExistingContentInLocalStore() async throws {
    let screencastModel = ContentTest.Mocks.screencast
    var screencast = screencastModel.0
    try database.write(screencast.save)
    
    let originalDuration = screencast.duration
    let originalDescription = screencast.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, screencast.duration)
    XCTAssertNotEqual(newDescription, screencast.descriptionPlainText)
    
    // Update the persisted model
    screencast.duration = newDuration
    screencast.descriptionPlainText = newDescription
    screencast = try await database.write { [screencast] db in
      try screencast.saved(db)
    }
    
    // Verify the changes persisted
    try await database.read { [screencast] db in
      let updatedScreencast = try Content.fetchOne(db, key: screencast.id).unwrapped
      XCTAssertEqual(newDuration, updatedScreencast.duration)
      XCTAssertEqual(newDescription, updatedScreencast.descriptionPlainText)
    }
    
    // We only have one item of content
    XCTAssertEqual(1, try allContents.count)
    
    // Now execute the download request
    let result = try await downloadService.requestDownload(contentID: screencast.id) { _ in
      .init(content: screencast, cacheUpdate: screencastModel.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    // No change to the content count
    XCTAssertEqual(1, try allContents.count)
    
    // The values will have reverted to those from the cache
    try await database.read { [key = screencast.id] db in
      let updatedScreencast = try Content.fetchOne(db, key: key).unwrapped
      XCTAssertEqual(originalDuration, updatedScreencast.duration)
      XCTAssertEqual(originalDescription, updatedScreencast.descriptionPlainText)
    }
  }
  
  func testRequestDownloadEpisodeAddsEpisodeAndCollectionToLocalStore() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    
    let episode = fullState.childContents.first!
    let result = try await downloadService.requestDownload(contentID: episode.id) { contentID in
      ContentPersistableState(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    let allContentIDs = fullState.childContents.map(\.id) + [collection.0.id]
    
    XCTAssertEqual(allContentIDs.count, try allContents.count)
    XCTAssertEqual(allContentIDs.sorted(), try allContents.map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadEpisodeUpdatesLocalDataStore() async throws {
    let collectionModel = ContentTest.Mocks.collection
    var collection = collectionModel.0
    let fullState = ContentPersistableState(content: collection, cacheUpdate: collectionModel.1)
    
    let episode = try fullState.childContents.first.unwrapped
    try await persistenceStore.persistContentGraph(for: fullState) { contentID in
      .init(contentID: contentID, cacheUpdate: collectionModel.1)
    }
    
    let originalDuration = collection.duration
    let originalDescription = collection.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, collection.duration)
    XCTAssertNotEqual(newDescription, collection.descriptionPlainText)
    
    // Update the CD model
    collection.duration = newDuration
    collection.descriptionPlainText = newDescription
    collection = try await database.write { [collection] db in
      try collection.saved(db)
    }
    
    // Confirm the change was persisted
    try await database.read { [key = collection.id] db in
      let updatedCollection = try Content.fetchOne(db, key: key).unwrapped
      XCTAssertEqual(newDuration, updatedCollection.duration)
      XCTAssertEqual(newDescription, updatedCollection.descriptionPlainText)
    }
    
    // Now execute the download request
    let result = try await downloadService.requestDownload(contentID: episode.id) { _ in
      .init(content: collection, cacheUpdate: collectionModel.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    // Adds all episodes and the collection to the DB
    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    
    // The values will have been reverted cos of the cache
    try await database.read { [key = collection.id] db in
      let updatedCollection = try Content.fetchOne(db, key: key).unwrapped
      XCTAssertEqual(originalDuration, updatedCollection.duration)
      XCTAssertEqual(originalDescription, updatedCollection.descriptionPlainText)
    }
  }
  
  func testRequestDownloadCollectionAddsCollectionAndEpisodesToLocalStore() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    
    let result = try await downloadService.requestDownload(contentID: collection.0.id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    XCTAssertEqual(
      (fullState.childContents.map(\.id) + [collection.0.id]) .sorted(),
      try allContents.map { Int($0.id) }.sorted()
    )
  }
  
  func testRequestDownloadCollectionUpdatesLocalDataStore() async throws {
    let collectionModel = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collectionModel.0, cacheUpdate: collectionModel.1)
    
    var episode = try XCTUnwrap(fullState.childContents.first)
    
    try await persistenceStore.persistContentGraph(for: fullState) { contentID in
      .init(contentID: contentID, cacheUpdate: collectionModel.1)
    }
    
    let originalDuration = episode.duration
    let originalDescription = episode.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, episode.duration)
    XCTAssertNotEqual(newDescription, episode.descriptionPlainText)
    
    // Update the persisted model
    episode.duration = newDuration
    episode.descriptionPlainText = newDescription
    episode = try await database.write { [episode] db in
      try episode.saved(db)
    }
    
    // Check that the new values were saved
    try await database.read { [key = episode.id] db in
      let updatedEpisode = try Content.fetchOne(db, key: key).unwrapped
      XCTAssertEqual(newDuration, updatedEpisode.duration)
      XCTAssertEqual(newDescription, updatedEpisode.descriptionPlainText)
    }
    
    // Now execute the download request
    let result = try await downloadService.requestDownload(contentID: collectionModel.0.id) { contentID in
      .init(contentID: contentID, cacheUpdate: collectionModel.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    // Added the correct number of models
    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    
    // The values reverted cos of the data cache
    try await database.read { [key = episode.id] db in
      let updatedEpisode = try Content.fetchOne(db, key: key).unwrapped
      XCTAssertEqual(originalDuration, updatedEpisode.duration)
      XCTAssertEqual(originalDescription, updatedEpisode.descriptionPlainText)
    }
  }
  
  func testRequestDownloadAddsDownloadToEpisodesAndCreatesOneForItsParentCollection() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    let episode = fullState.childContents.first!
    
    let result = try await downloadService.requestDownload(contentID: episode.id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)
    XCTAssertEqual(try allDownloads.count, 2)
    XCTAssertEqual(episode.id, try allDownloads.first?.contentID)
  }
  
  func testRequestAdditionalEpisodesUpdatesTheCollectionDownload() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    let episodes = fullState.childContents
    
    let result1 = try await downloadService.requestDownload(contentID: episodes[0].id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }
    let result2 = try await downloadService.requestDownload(contentID: episodes[1].id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }
    let result3 = try await downloadService.requestDownload(contentID: episodes[2].id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result1, .downloadRequestedButQueueInactive)
    XCTAssertEqual(result2, .downloadRequestedButQueueInactive)
    XCTAssertEqual(result3, .downloadRequestedButQueueInactive)
    XCTAssertEqual(4, try allDownloads.count)
  }
  
  func testRequestDownloadAddsDownloadToScreencasts() async throws {
    let screencast = ContentTest.Mocks.screencast
    let result = try await downloadService.requestDownload(contentID: screencast.0.id) { _ in
      .init(content: screencast.0, cacheUpdate: screencast.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)
    XCTAssertEqual(try allDownloads.count, 1)
    XCTAssertEqual(screencast.0.id, try allDownloads.first?.contentID)
  }
  
  func testRequestDownloadAddsDownloadToCollection() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    let result = try await downloadService.requestDownload(contentID: collection.0.id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    // Adds downloads to the collection and the individual episodes
    XCTAssertEqual(fullState.childContents.count + 1, try allDownloads.count)
    XCTAssertEqual(
      (fullState.childContents.map(\.id) + [collection.0.id]).sorted(),
      try allDownloads.map(\.contentID).sorted()
    )
  }
  
  func testRequestDownloadAddsDownloadInPendingState() async throws {
    let screencast = ContentTest.Mocks.screencast
    let result = try await downloadService.requestDownload(contentID: screencast.0.id) { _ in
      .init(content: screencast.0, cacheUpdate: screencast.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)
    XCTAssertEqual(.pending, try allDownloads.first?.state)
  }
  
  //: Download directory
  func testCreatesDownloadDirectory() throws {
    XCTAssert(
      try URL.downloadsDirectory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
    )
  }
  
  func testEmptiesDownloadsDirectoryIfNotLoggedIn() {
    userModelController.user = .none
    downloadService = .init(
      persistenceStore: persistenceStore,
      userModelController: userModelController,
      videosServiceProvider: { _ in self.videoService },
      settingsManager: App.objects.settingsManager
    )
    
    XCTAssertFalse(sampleFileExists)
  }
  
  func testEmptiesDownloadsDirectoryWhenLogsOut() {
    createSampleFile()
    
    userModelController.objectWillChange.send()
    userModelController.user = .none
    userModelController.objectDidChange.send()
    
    XCTAssertFalse(sampleFileExists)
  }
  
  func testEmptiesDownloadsDirectoryWhenUserDoesNotHaveDownloadPermission() {
    createSampleFile()
    
    userModelController.user = .noPermissions

    downloadService = .init(
      persistenceStore: persistenceStore,
      userModelController: userModelController,
      videosServiceProvider: { _ in self.videoService },
      settingsManager: App.objects.settingsManager
    )
    
    XCTAssertFalse(sampleFileExists)
  }
  
  func testEmptiesDownloadsDirectoryWhenPermissionsChange() {
    createSampleFile()
    
    userModelController.objectWillChange.send()
    userModelController.user = .noPermissions
    userModelController.objectDidChange.send()
    
    XCTAssertFalse(sampleFileExists)
  }
  
  func testDoesNotEmptyDownloadDirectoryIfUserHasDownloadPermission() {
    createSampleFile()
    
    userModelController.objectWillChange.send()
    userModelController.user = .withDownloads
    userModelController.objectDidChange.send()
    
    XCTAssert(sampleFileExists)
  }
  
  //: requestDownloadURL() Tests
  func testRequestDownloadURLRequestsDownloadURLForEpisode() async throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState(content: collection.0, cacheUpdate: collection.1)
    let episode = fullState.childContents.first!
    
    let result = try await downloadService.requestDownload(contentID: episode.id) { contentID in
      .init(contentID: contentID, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    XCTAssertEqual(videoService.getVideoDownloadCount, 0)
    await downloadService.requestDownloadURL(try XCTUnwrap(allDownloadQueueItems.first))
    XCTAssertEqual(videoService.getVideoDownloadCount, 1)
  }
  
  func testRequestDownloadURLRequestsDownloadsURLForScreencast() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    await downloadService.requestDownloadURL(downloadQueueItem)
    XCTAssertEqual(videoService.getVideoDownloadCount, 1)
  }
  
  func testRequestDownloadURLDoesNothingForCollection() async throws {
    let collection = ContentTest.Mocks.collection
    let result = try await downloadService.requestDownload(contentID: collection.0.id) { _ in
      .init(content: collection.0, cacheUpdate: collection.1)
    }

    XCTAssertEqual(result, .downloadRequestedButQueueInactive)

    let downloadQueueItem = try allDownloadQueueItems.first { $0.content.contentType == .collection }.unwrapped
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    await downloadService.enqueue(downloadQueueItem: downloadQueueItem)
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLDoesNothingForDownloadInWrongState() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    var download = downloadQueueItem.download
    
    download.state = .urlRequested
    
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    await downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLUpdatesDownloadInCallback() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    
    XCTAssertNil(downloadQueueItem.download.remoteURL)
    XCTAssertNil(downloadQueueItem.download.lastValidatedAt)
    XCTAssertEqual(Download.State.pending, downloadQueueItem.download.state)
    
    await downloadService.requestDownloadURL(downloadQueueItem)
    
    try await database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertNotNil(download.remoteURL)
      XCTAssertNotNil(download.lastValidatedAt)
    }
  }
  
  func testRequestDownloadUpdatesTheStateCorrectly() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem

    await
    downloadService.requestDownloadURL(downloadQueueItem)
    
    try await database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertEqual(Download.State.urlRequested, download.state)
    }
  }
  
  func testEnqueueSetsPropertiesCorrectly() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    var download = downloadQueueItem.download
    // Update to include the URL
    download.remoteURL = URL(string: "https://example.com/video.mp4")
    download.state = .readyForDownload
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    await downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try await database.read { [key = download.id] db in
      let refreshedDownload = try Download.fetchOne(db, key: key).unwrapped
      XCTAssertNotNil(refreshedDownload.localURL)
      XCTAssertNotNil(refreshedDownload.fileName)
      XCTAssertEqual(Download.State.enqueued, refreshedDownload.state)
    }
  }
  
  func testEnqueueDoesNothingForADownloadWithoutARemoteURL() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    var download = downloadQueueItem.download
    download.state = .urlRequested
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    
    await downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try await database.read { [key = download.id] db in
      let refreshedDownload = try Download.fetchOne(db, key: key).unwrapped
      XCTAssertNil(refreshedDownload.fileName)
      XCTAssertNil(refreshedDownload.localURL)
      XCTAssertEqual(Download.State.urlRequested, refreshedDownload.state)
    }
  }
  
  func testEnqueueDoesNothingForDownloadInTheWrongState() async throws {
    let downloadQueueItem = try await sampleDownloadQueueItem
    var download = downloadQueueItem.download
    download.remoteURL = URL(string: "https://example.com/amazing.mp4")
    download.state = .pending
    download = try await database.write { [download] db in
      try download.saved(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    
    await downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try await database.read { [key = download.id] db in
      let refreshedDownload = try Download.fetchOne(db, key: key).unwrapped
      XCTAssertNil(refreshedDownload.fileName)
      XCTAssertNil(refreshedDownload.localURL)
      XCTAssertEqual(Download.State.pending, refreshedDownload.state)
    }
  }
}

// MARK: - private
private extension DownloadServiceTest {
  var allDownloadQueueItems: [PersistenceStore.DownloadQueueItem] {
    get throws {
      try database.read { db in
        let request = Download.including(required: Download.content)
        return try PersistenceStore.DownloadQueueItem.fetchAll(db, request)
      }
    }
  }

  var sampleDownloadQueueItem: PersistenceStore.DownloadQueueItem {
    get async throws {
      let screencast = ContentTest.Mocks.screencast
      let result = try await downloadService.requestDownload(contentID: screencast.0.id) { _ in
        .init(content: screencast.0, cacheUpdate: screencast.1)
      }

      XCTAssertEqual(result, .downloadRequestedButQueueInactive)

      return .init(
        download: try XCTUnwrap(allDownloads.first),
        content: try XCTUnwrap(allContents.first)
      )
    }
  }

  var sampleDownload: Download {
    get async throws { try await sampleDownloadQueueItem.download }
  }

  var sampleFileURL: URL {
    .downloadsDirectory.appendingPathComponent("sample_file")
  }

  var sampleFileExists: Bool {
    FileManager.default.fileExists(atPath: sampleFileURL.path)
  }

  func createSampleFile() {
    XCTAssertFalse(sampleFileExists)
    FileManager.default.createFile(atPath: sampleFileURL.path, contents: nil)
    XCTAssert(sampleFileExists)
  }
}
