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
@testable import Emitron

class DownloadServiceTest: XCTestCase {
  private var database: DatabaseWriter!
  private var persistenceStore: PersistenceStore!
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var userModelController: UserMCMock!
  
  override func setUp() {
    database = try! EmitronDatabase.testDatabase()
    persistenceStore = PersistenceStore(db: database)
    userModelController = UserMCMock.withDownloads
    downloadService = DownloadService(persistenceStore: persistenceStore,
                                      userModelController: userModelController,
                                      videosServiceProvider: { _ in self.videoService })
    
    // Check it's all empty
    XCTAssertEqual(0, getAllContents().count)
    XCTAssertEqual(0, getAllDownloads().count)
  }
  
  override func tearDown() {
    videoService.reset()
    deleteSampleFile(fileManager: FileManager.default)
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
  
  func getAllDownloadQueueItems() -> [PersistenceStore.DownloadQueueItem] {
    try! database.read { db in
      let request = Download.including(required: Download.content)
      return try PersistenceStore.DownloadQueueItem.fetchAll(db, request)
    }
  }
  
  func sampleDownloadQueueItem() -> PersistenceStore.DownloadQueueItem {
    let screencast = ContentTest.Mocks.screencast
    downloadService.requestDownload(contentId: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    let download = getAllDownloads().first!
    let content = getAllContents().first!
    return PersistenceStore.DownloadQueueItem(download: download, content: content)
  }
  
  func sampleDownload() -> Download {
    sampleDownloadQueueItem().download
  }
  
  func downloadsDirectory(fileManager: FileManager) -> URL {
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    return documentsDirectory!.appendingPathComponent("downloads", isDirectory: true)
  }
  
  func createSampleFile(fileManager: FileManager) -> URL {
    // Create a sample file
    let directory = downloadsDirectory(fileManager: fileManager)
    let sampleFile = directory.appendingPathComponent("sample_file")
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
    
    fileManager.createFile(atPath: sampleFile.path, contents: .none, attributes: .none)
    XCTAssert(fileManager.fileExists(atPath: sampleFile.path))
    
    return sampleFile
  }
  
  func deleteSampleFile(fileManager: FileManager) {
    let directory = downloadsDirectory(fileManager: fileManager)
    let sampleFile = directory.appendingPathComponent("sample_file")
    
    if fileManager.fileExists(atPath: sampleFile.path) {
      try! fileManager.removeItem(at: sampleFile)
    }
  }
  
  //: requestDownload(content:) Tests
  func testRequestDownloadScreencastAddsContentToLocalStore() {
    let screencast = ContentTest.Mocks.screencast
    downloadService.requestDownload(contentId: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    
    XCTAssertEqual(1, getAllContents().count)
    XCTAssertEqual(screencast.0.id, Int(getAllContents().first!.id))
  }
  
  func testRequestDownloadScreencastUpdatesExistingContentInLocalStore() throws {
    let screencastModel = ContentTest.Mocks.screencast
    var screencast = screencastModel.0
    try database.write { db in
      try screencast.save(db)
    }
    
    let originalDuration = screencast.duration
    let originalDescription = screencast.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, screencast.duration)
    XCTAssertNotEqual(newDescription, screencast.descriptionPlainText)
    
    // Update the persisted model
    screencast.duration = newDuration
    screencast.descriptionPlainText = newDescription
    try database.write { db in
      try screencast.save(db)
    }
    
    // Verify the changes persisted
    try database.read { db in
      let updatedScreencast = try Content.fetchOne(db, key: screencast.id)
      XCTAssertEqual(newDuration, updatedScreencast!.duration)
      XCTAssertEqual(newDescription, updatedScreencast!.descriptionPlainText)
    }
    
    // We only have one item of content
    XCTAssertEqual(1, getAllContents().count)
    
    // Now execute the download request
    downloadService.requestDownload(contentId: screencast.id) { _ in
      ContentPersistableState.persistableState(for: screencast, with: screencastModel.1)
    }
    
    // No change to the content count
    XCTAssertEqual(1, getAllContents().count)
    
    // The values will have reverted to those from the cache
    try database.read { db in
      let updatedScreencast = try Content.fetchOne(db, key: screencast.id)
      XCTAssertEqual(originalDuration, updatedScreencast!.duration)
      XCTAssertEqual(originalDescription, updatedScreencast!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadEpisodeAddsEpisodeAndCollectionToLocalStore() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    
    let episode = fullState.childContents.first!
    downloadService.requestDownload(contentId: episode.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    
    let allContentIds = fullState.childContents.map({ $0.id }) + [collection.0.id]
    
    XCTAssertEqual(allContentIds.count, getAllContents().count)
    XCTAssertEqual(allContentIds.sorted() , getAllContents().map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadEpisodeUpdatesLocalDataStore() throws {
    let collectionModel = ContentTest.Mocks.collection
    var collection = collectionModel.0
    let fullState = ContentPersistableState.persistableState(for: collection, with: collectionModel.1)
    
    let episode = fullState.childContents.first!
    try persistenceStore.persistContentGraph(for: fullState, contentLookup: { (contentId) in
      ContentPersistableState.persistableState(for: contentId, with: collectionModel.1)
    })
    
    let originalDuration = collection.duration
    let originalDescription = collection.descriptionPlainText
    
    let newDuration = 1234
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, collection.duration)
    XCTAssertNotEqual(newDescription, collection.descriptionPlainText)
    
    // Update the CD model
    collection.duration = newDuration
    collection.descriptionPlainText = newDescription
    try database.write { db in
      try collection.save(db)
    }
    
    // Confirm the chnage was persisted
    try database.read { db in
      let updatedCollection = try Content.fetchOne(db, key: collection.id)
      XCTAssertEqual(newDuration, updatedCollection!.duration)
      XCTAssertEqual(newDescription, updatedCollection!.descriptionPlainText)
    }
    
    // Now execute the download request
    downloadService.requestDownload(contentId: episode.id) { _ in
      ContentPersistableState.persistableState(for: collection, with: collectionModel.1)
    }
    
    // Adds all episodes and the collection to the DB
    XCTAssertEqual(fullState.childContents.count + 1, getAllContents().count)
    
    // The values will have been reverted cos of the cache
    try database.read { db in
      let updatedCollection = try Content.fetchOne(db, key: collection.id)
      XCTAssertEqual(originalDuration, updatedCollection!.duration)
      XCTAssertEqual(originalDescription, updatedCollection!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadCollectionAddsCollectionAndEpisodesToLocalStore() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    
    downloadService.requestDownload(contentId: collection.0.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    
    XCTAssertEqual(fullState.childContents.count + 1, getAllContents().count)
    XCTAssertEqual((fullState.childContents.map { $0.id } + [collection.0.id]) .sorted() , getAllContents().map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadCollectionUpdatesLocalDataStore() throws {
    let collectionModel = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collectionModel.0, with: collectionModel.1)
    
    var episode = fullState.childContents.first!
    
    try persistenceStore.persistContentGraph(for: fullState, contentLookup: { (contentId) in
      ContentPersistableState.persistableState(for: contentId, with: collectionModel.1)
    })
    
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
    downloadService.requestDownload(contentId: collectionModel.0.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collectionModel.1)
    }
    
    // Added the correct number of models
    XCTAssertEqual(fullState.childContents.count + 1, getAllContents().count)
    
    // The values reverted cos of the data cache
    try database.read { db in
      let updatedEpisode = try Content.fetchOne(db, key: episode.id)
      XCTAssertEqual(originalDuration, updatedEpisode!.duration)
      XCTAssertEqual(originalDescription, updatedEpisode!.descriptionPlainText)
    }
  }
  
  func testRequestDownloadAddsDownloadToEpisodesAndCreatesOneForItsParentCollection() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episode = fullState.childContents.first!
    
    downloadService.requestDownload(contentId: episode.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    
    XCTAssertEqual(2, getAllDownloads().count)
    
    let download = getAllDownloads().first!
    XCTAssertEqual(episode.id, download.contentId)
  }
  
  func testRequestAdditionalEpisodesUpdatesTheCollectionDownload() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episodes = fullState.childContents
    
    downloadService.requestDownload(contentId: episodes[0].id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    downloadService.requestDownload(contentId: episodes[1].id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    downloadService.requestDownload(contentId: episodes[2].id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    
    XCTAssertEqual(4, getAllDownloads().count)
  }
  
  func testRequestDownloadAddsDownloadToScreencasts() {
    let screencast = ContentTest.Mocks.screencast
    downloadService.requestDownload(contentId: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    
    XCTAssertEqual(1, getAllDownloads().count)
    let download = getAllDownloads().first!
    XCTAssertEqual(screencast.0.id, download.contentId)
  }
  
  func testRequestDownloadAddsDownloadToCollection() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    downloadService.requestDownload(contentId: collection.0.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }

    // Adds downloads to the collection and the individual episodes
    XCTAssertEqual(fullState.childContents.count + 1, getAllDownloads().count)
    XCTAssertEqual(
      (fullState.childContents.map { $0.id } + [collection.0.id]).sorted(),
      getAllDownloads().map { $0.contentId }.sorted()
    )
  }
  
  func testRequestDownloadAddsDownloadInPendingState() {
    let screencast = ContentTest.Mocks.screencast
    downloadService.requestDownload(contentId: screencast.0.id) { _ in
      ContentPersistableState.persistableState(for: screencast.0, with: screencast.1)
    }
    
    let download = getAllDownloads().first!
    XCTAssertEqual(.pending, download.state)
  }
  
  //: Download directory
  func testCreatesDownloadDirectory() {
    // This is created at instantiation of the DownloadService object
    let fileManager = FileManager.default
    let documentsDirectories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = documentsDirectories.first
    
    // Can find the documents directory
    XCTAssertNotNil(documentsDirectory)
    
    let downloadsDirectory = documentsDirectory!.appendingPathComponent("downloads", isDirectory: true)
    
    // The downloads subdirectory exists
    let resourceValues = try! downloadsDirectory.resourceValues(forKeys: [.isExcludedFromBackupKey])
    
    // The directory is marked as excluded from backups
    XCTAssert(resourceValues.isExcludedFromBackup == true)
  }
  
  func testEmptiesDownloadsDirectoryIfNotLoggedIn() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = .none
    downloadService = DownloadService(persistenceStore: persistenceStore,
                                      userModelController: userModelController,
                                      videosServiceProvider: { _ in self.videoService })
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenLogsOut() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.objectWillChange.send()
    userModelController.user = .none
    userModelController.objectDidChange.send()
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenUserDoesNotHaveDownloadPermission() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = User.noPermissions
    downloadService = DownloadService(persistenceStore: persistenceStore,
                                      userModelController: userModelController,
                                      videosServiceProvider: { _ in self.videoService })
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenPermissionsChange() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.objectWillChange.send()
    userModelController.user = User.noPermissions
    userModelController.objectDidChange.send()
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testDoesNotEmptyDownloadDirectoryIfUserHasDownloadPermission() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.objectWillChange.send()
    userModelController.user = User.withDownloads
    userModelController.objectDidChange.send()
    
    XCTAssert(fileManager.fileExists(atPath: sampleFile.path))
  }
  
  //: requestDownloadUrl() Tests
  func testRequestDownloadUrlRequestsDownloadURLForEpisode() {
    let collection = ContentTest.Mocks.collection
    let fullState = ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    let episode = fullState.childContents.first!
    
    downloadService.requestDownload(contentId: episode.id) { contentId in
      ContentPersistableState.persistableState(for: contentId, with: collection.1)
    }
    
    let downloadQueueItem = getAllDownloadQueueItems().first!
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(downloadQueueItem)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlRequestsDownloadsURLForScreencast() {
    let downloadQueueItem = sampleDownloadQueueItem()
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(downloadQueueItem)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlDoesNothingForCollection() {
    let collection = ContentTest.Mocks.collection
    downloadService.requestDownload(contentId: collection.0.id) { _ in
      ContentPersistableState.persistableState(for: collection.0, with: collection.1)
    }
    
    let downloadQueueItem = getAllDownloadQueueItems().first { $0.content.contentType == .collection }
    
    XCTAssertNotNil(downloadQueueItem)
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.enqueue(downloadQueueItem: downloadQueueItem!)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlDoesNothingForDownloadInWrongState() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
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
  
  func testRequestDownloadUrlUpdatesDownloadInCallback() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
    
    XCTAssertNil(downloadQueueItem.download.remoteUrl)
    XCTAssertNil(downloadQueueItem.download.lastValidatedAt)
    XCTAssertEqual(Download.State.pending, downloadQueueItem.download.state)
    
    downloadService.requestDownloadUrl(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertNotNil(download.remoteUrl)
      XCTAssertNotNil(download.lastValidatedAt)
    }
  }
  
  func testRequestDownloadUrlRespectsTheUserPreferencesOnQuality() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
    let attachment = AttachmentTest.Mocks.downloads.0.first { $0.kind == .sdVideoFile }!
    
    UserDefaults.standard.set(Attachment.Kind.sdVideoFile.apiValue, forKey: UserDefaultsKey.downloadQuality.rawValue)
    
    downloadService.requestDownloadUrl(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertNotNil(download.remoteUrl)
      XCTAssertEqual(attachment.url, download.remoteUrl)
    }
    
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.downloadQuality.rawValue)
  }
  
  func testRequestDownloadDefaultsToHDQuality() throws {
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.downloadQuality.rawValue)
    
    let downloadQueueItem = sampleDownloadQueueItem()
    let attachment = AttachmentTest.Mocks.downloads.0.first { $0.kind == .hdVideoFile }!
    
    downloadService.requestDownloadUrl(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertNotNil(download.remoteUrl)
      XCTAssertEqual(attachment.url, download.remoteUrl)
    }
  }
  
  func testRequestDownloadUpdatesTheStateCorrectly() throws {
    let downloadQueueItem = sampleDownloadQueueItem()

    downloadService.requestDownloadUrl(downloadQueueItem)
    
    try database.read { db in
      let download = try Download.fetchOne(db, key: downloadQueueItem.download.id)!
      XCTAssertEqual(Download.State.urlRequested, download.state)
    }
  }
  
  func testEnqueueSetsPropertiesCorrectly() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
    var download = downloadQueueItem.download
    // Update to include the URL
    download.remoteUrl = URL(string: "https://example.com/video.mp4")
    download.state = .readyForDownload
    try database.write { db in
      try download.save(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertNotNil(refreshedDownload.localUrl)
      XCTAssertNotNil(refreshedDownload.fileName)
      XCTAssertEqual(Download.State.enqueued, refreshedDownload.state)
    }
  }
  
  func testEnqueueUpdatesStateToCompletedIfItFindsDownload() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
    var download = downloadQueueItem.download
    download.remoteUrl = URL(string: "https://example.com/amazing.mp4")
    download.fileName = "\(downloadQueueItem.content.videoIdentifier!).mp4"
    download.state = .readyForDownload
    try database.write { db in
      try download.save(db)
    }
    
    let fileManager = FileManager.default
    let documentsDirectories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = documentsDirectories.first
    let downloadsDirectory = documentsDirectory!.appendingPathComponent("downloads", isDirectory: true)
    
    let sampleFile = downloadsDirectory.appendingPathComponent(download.fileName!)
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
    
    fileManager.createFile(atPath: sampleFile.path, contents: nil)

    XCTAssert(fileManager.fileExists(atPath: sampleFile.path))
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertEqual(Download.State.complete, refreshedDownload.state)
      XCTAssertEqual(sampleFile, refreshedDownload.localUrl)
    }
    
    try! fileManager.removeItem(at: sampleFile)
  }
  
  func testEnqueueDoesNothingForADownloadWithoutARemoteUrl() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
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
      XCTAssertNil(refreshedDownload.localUrl)
      XCTAssertEqual(Download.State.urlRequested , refreshedDownload.state)
    }
  }
  
  func testEnqueueDoesNothingForDownloadInTheWrongState() throws {
    let downloadQueueItem = sampleDownloadQueueItem()
    var download = downloadQueueItem.download
    download.remoteUrl = URL(string: "https://example.com/amazing.mp4")
    download.state = .pending
    try database.write { db in
      try download.save(db)
    }
    
    let newQueueItem = PersistenceStore.DownloadQueueItem(download: download, content: downloadQueueItem.content)
    
    downloadService.enqueue(downloadQueueItem: newQueueItem)
    
    try database.read { db in
      let refreshedDownload = try Download.fetchOne(db, key: download.id)!
      XCTAssertNil(refreshedDownload.fileName)
      XCTAssertNil(refreshedDownload.localUrl)
      XCTAssertEqual(Download.State.pending , refreshedDownload.state)
    }
  }
}
