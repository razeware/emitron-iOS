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

class DownloadServiceTest: XCTestCase {
  private var database: DatabaseWriter!
  private var persistenceStore: PersistenceStore!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var userModelController: UserMCMock!
  private var settingsManager: SettingsManager!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try EmitronDatabase.testDatabase()
    persistenceStore = PersistenceStore(db: database)
    userModelController = .init(user: .withDownloads)
    settingsManager = App.objects.settingsManager
    downloadService = DownloadService(
      persistenceStore: persistenceStore,
      userModelController: userModelController,
      videosServiceProvider: { _ in self.videoService },
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
  func testRequestDownloadScreencastAddsContentToLocalStore() throws {
    let screencast = ContentTest.Mocks.screencast
    let recorder = downloadService.requestDownload(contentID: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 3)
    XCTAssert(completion == .finished)
    
    XCTAssertEqual(1, try allContents.count)
    XCTAssertEqual(screencast.0.id, Int(try allContents.first!.id))
  }
  
  func testRequestDownloadScreencastUpdatesExistingContentInLocalStore() throws {
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
    try database.write(screencast.save)
    
    // Verify the changes persisted
    try database.read { db in
      let updatedScreencast = try Content.fetchOne(db, key: screencast.id)
      XCTAssertEqual(newDuration, updatedScreencast!.duration)
      XCTAssertEqual(newDescription, updatedScreencast!.descriptionPlainText)
    }
    
    // We only have one item of content
    XCTAssertEqual(1, try allContents.count)
    
    // Now execute the download request
    let recorder = downloadService.requestDownload(contentID: screencast.id) { _ in
      ContentPersistableState.persistableState(for: screencast, with: screencastModel.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    // No change to the content count
    XCTAssertEqual(1, try allContents.count)
    
    // The values will have reverted to those from the cache
    try database.read { db in
      let updatedScreencast = try Content.fetchOne(db, key: screencast.id)
      XCTAssertEqual(originalDuration, updatedScreencast!.duration)
      XCTAssertEqual(originalDescription, updatedScreencast!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadEpisodeAddsEpisodeAndCollectionToLocalStore() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    
    let episode = fullState.childContents.first!
    let recorder = downloadService.requestDownload(contentID: episode.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    let allContentIDs = fullState.childContents.map(\.id) + [collection.0.id]
    
    XCTAssertEqual(allContentIDs.count, try allContents.count)
    XCTAssertEqual(allContentIDs.sorted(), try allContents.map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadEpisodeUpdatesLocalDataStore() throws {
    let collectionModel = ContentTest.Mocks.collection
    var collection = collectionModel.0
    let fullState = ContentPersistableState.persistableState(for: collection, with: collectionModel.1)
    
    let episode = fullState.childContents.first!
    let recorder = persistenceStore.persistContentGraph(for: fullState, contentLookup: { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collectionModel.1)
    })
      .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    if case .failure = completion {
      XCTFail("Failed")
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
    try database.write(collection.save)
    
    // Confirm the change was persisted
    try database.read { db in
      let updatedCollection = try Content.fetchOne(db, key: collection.id)
      XCTAssertEqual(newDuration, updatedCollection!.duration)
      XCTAssertEqual(newDescription, updatedCollection!.descriptionPlainText)
    }
    
    // Now execute the download request
    let anotherRecorder = downloadService.requestDownload(contentID: episode.id) { _ in
      ContentPersistableState.persistableState(for: collection, with: collectionModel.1)
    }
    .record()
    
    let anotherCompletion = try wait(for: anotherRecorder.completion, timeout: 10)
    XCTAssert(anotherCompletion == .finished)
    
    // Adds all episodes and the collection to the DB
    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    
    // The values will have been reverted cos of the cache
    try database.read { db in
      let updatedCollection = try Content.fetchOne(db, key: collection.id)
      XCTAssertEqual(originalDuration, updatedCollection!.duration)
      XCTAssertEqual(originalDescription, updatedCollection!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadCollectionAddsCollectionAndEpisodesToLocalStore() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    
    let recorder = downloadService.requestDownload(contentID: collection.0.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    XCTAssertEqual(
      (fullState.childContents.map(\.id) + [collection.0.id]) .sorted(),
      try allContents.map { Int($0.id) }.sorted()
    )
  }
  
  func testRequestDownloadCollectionUpdatesLocalDataStore() throws {
    let collectionModel = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collectionModel.0, with: collectionModel.1)
    
    var episode = fullState.childContents.first!
    
    let recorder = persistenceStore.persistContentGraph(for: fullState, contentLookup: { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collectionModel.1)
    })
      .record()
    
    _ = try wait(for: recorder.completion, timeout: 10)
    
    let originalDuration = episode.duration
    let originalDescription = episode.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, episode.duration)
    XCTAssertNotEqual(newDescription, episode.descriptionPlainText)
    
    // Update the persisted model
    episode.duration = newDuration
    episode.descriptionPlainText = newDescription
    try database.write { db in
      try episode.save(db)
    }
    
    // Check that the new values were saved
    try database.read { db in
      let updatedEpisode = try Content.fetchOne(db, key: episode.id)
      XCTAssertEqual(newDuration, updatedEpisode!.duration)
      XCTAssertEqual(newDescription, updatedEpisode!.descriptionPlainText)
    }
    
    // Now execute the download request
    let recorder2 = downloadService.requestDownload(contentID: collectionModel.0.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collectionModel.1)
    }
    .record()
    
    let completion = try wait(for: recorder2.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    // Added the correct number of models
    XCTAssertEqual(fullState.childContents.count + 1, try allContents.count)
    
    // The values reverted cos of the data cache
    try database.read { db in
      let updatedEpisode = try Content.fetchOne(db, key: episode.id)
      XCTAssertEqual(originalDuration, updatedEpisode!.duration)
      XCTAssertEqual(originalDescription, updatedEpisode!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadAddsDownloadToEpisodesAndCreatesOneForItsParentCollection() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episode = fullState.childContents.first!
    
    let recorder = downloadService.requestDownload(contentID: episode.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    XCTAssertEqual(2, try allDownloads.count)
    
    let download = try allDownloads.first!
    XCTAssertEqual(episode.id, download.contentID)
  }
  
  func testRequestAdditionalEpisodesUpdatesTheCollectionDownload() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episodes = fullState.childContents
    
    let recorder1 = downloadService.requestDownload(contentID: episodes[0].id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    let recorder2 = downloadService.requestDownload(contentID: episodes[1].id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    let recorder3 = downloadService.requestDownload(contentID: episodes[2].id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    _ = try wait(for: recorder1.completion, timeout: 10)
    _ = try wait(for: recorder2.completion, timeout: 10)
    _ = try wait(for: recorder3.completion, timeout: 10)
    
    XCTAssertEqual(4, try allDownloads.count)
  }
  
  func testRequestDownloadAddsDownloadToScreencasts() throws {
    let screencast = ContentTest.Mocks.screencast
    let recorder = downloadService.requestDownload(contentID: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    XCTAssertEqual(1, try allDownloads.count)
    let download = try allDownloads.first!
    XCTAssertEqual(screencast.0.id, download.contentID)
  }
  
  func testRequestDownloadAddsDownloadToCollection() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let recorder = downloadService.requestDownload(contentID: collection.0.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 20)
    XCTAssert(completion == .finished)

    // Adds downloads to the collection and the individual episodes
    XCTAssertEqual(fullState.childContents.count + 1, try allDownloads.count)
    XCTAssertEqual(
      (fullState.childContents.map(\.id) + [collection.0.id]).sorted(),
      try allDownloads.map(\.contentID).sorted()
    )
  }
  
  func testRequestDownloadAddsDownloadInPendingState() throws {
    let screencast = ContentTest.Mocks.screencast
    let recorder = downloadService.requestDownload(contentID: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    let download = try allDownloads.first!
    XCTAssertEqual(.pending, download.state)
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
  func testRequestDownloadURLRequestsDownloadURLForEpisode() throws {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episode = fullState.childContents.first!
    
    let recorder = downloadService.requestDownload(contentID: episode.id) { contentID in
      ContentPersistableState.persistableState(for: contentID, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(completion == .finished)
    
    let downloadQueueItem = try allDownloadQueueItems.first!
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadURL(downloadQueueItem)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLRequestsDownloadsURLForScreencast() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadURL(downloadQueueItem)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLDoesNothingForCollection() throws {
    let collection = ContentTest.Mocks.collection
    let recorder = downloadService.requestDownload(contentID: collection.0.id) { _ in
      ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    }
    .record()
    
    let completion = try wait(for: recorder.completion, timeout: 10)
    XCTAssert(.finished == completion)
    
    let downloadQueueItem = try allDownloadQueueItems.first { $0.content.contentType == .collection }
    
    XCTAssertNotNil(downloadQueueItem)
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.enqueue(downloadQueueItem: downloadQueueItem!)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLDoesNothingForDownloadInWrongState() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    var download = downloadQueueItem.download
    
    download.state = .urlRequested
    
    try database.write { db in
      try download.save(db)
    }
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadURLUpdatesDownloadInCallback() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    
    XCTAssertNil(downloadQueueItem.download.remoteURL)
    XCTAssertNil(downloadQueueItem.download.lastValidatedAt)
    XCTAssertEqual(Download.State.pending, downloadQueueItem.download.state)
    
    downloadService.requestDownloadURL(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertNotNil(download.remoteURL)
      XCTAssertNotNil(download.lastValidatedAt)
    }
  }
  
  func testRequestDownloadUpdatesTheStateCorrectly() throws {
    let downloadQueueItem = try sampleDownloadQueueItem

    downloadService.requestDownloadURL(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertEqual(Download.State.urlRequested, download.state)
    }
  }
  
  func testEnqueueSetsPropertiesCorrectly() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    var download = downloadQueueItem.download
    // Update to include the URL
    download.remoteURL = URL(string: "https://example.com/video.mp4")
    download.state = .readyForDownload
    try database.write { db in
      try download.save(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertNotNil(refreshedDownload.localURL)
      XCTAssertNotNil(refreshedDownload.fileName)
      XCTAssertEqual(Download.State.enqueued, refreshedDownload.state)
    }
  }
  
  func testEnqueueDoesNothingForADownloadWithoutARemoteURL() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    var download = downloadQueueItem.download
    download.state = .urlRequested
    try database.write { db in
      try download.save(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertNil(refreshedDownload.fileName)
      XCTAssertNil(refreshedDownload.localURL)
      XCTAssertEqual(Download.State.urlRequested, refreshedDownload.state)
    }
  }
  
  func testEnqueueDoesNothingForDownloadInTheWrongState() throws {
    let downloadQueueItem = try sampleDownloadQueueItem
    var download = downloadQueueItem.download
    download.remoteURL = URL(string: "https://example.com/amazing.mp4")
    download.state = .pending
    try database.write { db in
      try download.save(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertNil(refreshedDownload.fileName)
      XCTAssertNil(refreshedDownload.localURL)
      XCTAssertEqual(Download.State.pending, refreshedDownload.state)
    }
  }
}

// MARK: - private
private extension DownloadServiceTest {
  var allContents: [Content] {
    get throws { try database.read(Content.fetchAll) }
  }

  var allDownloads: [Download] {
    get throws { try database.read(Download.fetchAll) }
  }

  var allDownloadQueueItems: [PersistenceStore.DownloadQueueItem] {
    get throws {
      try database.read { db in
        let request = Download.including(required: Download.content)
        return try PersistenceStore.DownloadQueueItem.fetchAll(db, request)
      }
    }
  }

  var sampleDownloadQueueItem: PersistenceStore.DownloadQueueItem {
    get throws {
      let screencast = ContentTest.Mocks.screencast
      let recorder = downloadService.requestDownload(contentID: screencast.0.id) { _ in
        ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
      }
        .record()

      let completion = try wait(for: recorder.completion, timeout: 10)
      XCTAssert(completion == .finished)

      let download = try allDownloads.first!
      let content = try allContents.first!
      return .init(download: download, content: content)
    }
  }

  var sampleDownload: Download {
    get throws { try sampleDownloadQueueItem.download }
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
