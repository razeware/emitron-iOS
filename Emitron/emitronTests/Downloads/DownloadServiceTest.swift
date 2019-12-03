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
@testable import Emitron

class DownloadServiceTest: XCTestCase {
  
  private var videoService = VideosServiceMock()
  private var downloadService: DownloadService!
  private var coreDataStack: CoreDataStack!
  private var userModelController: UserMCMock!
  
  override func setUp() {
    coreDataStack = CoreDataStack(modelName: "Emitron", persistentStoreType: NSInMemoryStoreType)
    coreDataStack.setupPersistentContainer()
    userModelController = UserMCMock.withDownloads
    downloadService = DownloadService(coreDataStack: coreDataStack, userModelController: userModelController, videosServiceProvider: { _ in self.videoService })
    
    // Check it's all empty
    XCTAssertEqual(0, getAllContents().count)
    XCTAssertEqual(0, getAllDownloads().count)
  }
  
  override func tearDown() {
    videoService.reset()
    deleteSampleFile(fileManager: FileManager.default)
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
    let screencast = ContentDetailsModelTest.Mocks.screencast
    downloadService.requestDownload(content: screencast)
    
    XCTAssertEqual(1, getAllContents().count)
    XCTAssertEqual(screencast.id, Int(getAllContents().first!.id))
  }
  
  func testRequestDownloadScreencastUpdatesExistingContentInLocalStore() {
    let screencastModel = ContentDetailsModelTest.Mocks.screencast
    let screencast = Contents(context: coreDataContext)
    screencast.update(from: screencastModel)
    
    let newDuration = Int64(1234)
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, screencast.duration)
    XCTAssertNotEqual(newDescription, screencast.desc)
    
    // Update the CD model
    screencast.duration = newDuration
    screencast.desc = newDescription
    try! coreDataContext.save()
    
    // Check that we persisted the values to CD correctly
    XCTAssertEqual(newDuration, screencast.duration)
    XCTAssertEqual(newDescription, screencast.desc)
    
    // We only have one item of content
    XCTAssertEqual(1, getAllContents().count)
    
    // Now execute the download request
    downloadService.requestDownload(content: screencastModel)
    
    // No change to the content count
    XCTAssertEqual(1, getAllContents().count)
    
    // And that the values have been updated in CD appropriately
    XCTAssertEqual(Int64(screencastModel.duration), screencast.duration)
    XCTAssertEqual(screencastModel.desc, screencast.desc)
  }
  
  func testRequestDownloadEpisodeAddsEpisodeAndCollectionToLocalStore() {
    let collection = ContentDetailsModelTest.Mocks.collection
    let episode = collection.childContents.first!
    downloadService.requestDownload(content: episode)
    
    XCTAssertEqual(2, getAllContents().count)
    XCTAssertEqual([episode.id, collection.id].sorted() , getAllContents().map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadEpisodeUpdatesLocalDataStore() {
    let collectionModel = ContentDetailsModelTest.Mocks.collection
    let episodeModel = collectionModel.childContents.first!
    
    let collection = Contents(context: coreDataContext)
    collection.update(from: collectionModel)
    
    let newDuration = Int64(1234)
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, collection.duration)
    XCTAssertNotEqual(newDescription, collection.desc)
    
    // Update the CD model
    collection.duration = newDuration
    collection.desc = newDescription
    try! coreDataContext.save()
    
    // Check that we persisted the values to CD correctly
    XCTAssertEqual(newDuration, collection.duration)
    XCTAssertEqual(newDescription, collection.desc)
    
    // We only have one item of content
    XCTAssertEqual(1, getAllContents().count)
    
    // Now execute the download request
    downloadService.requestDownload(content: episodeModel)
    
    // Added a single episode to the content count
    XCTAssertEqual(2, getAllContents().count)
    
    // And that the values have been updated in CD appropriately
    XCTAssertEqual(Int64(collectionModel.duration), collection.duration)
    XCTAssertEqual(collectionModel.desc, collection.desc)
  }
  
  func testRequestDownloadCollectionAddsCollectionAndEpisodesToLocalStore() {
    let collection = ContentDetailsModelTest.Mocks.collection
    downloadService.requestDownload(content: collection)
    
    XCTAssertEqual(collection.childContents.count + 1, getAllContents().count)
    XCTAssertEqual((collection.childContents.map { $0.id } + [collection.id]) .sorted() , getAllContents().map { Int($0.id) }.sorted())
  }
  
  func testRequestDownloadCollectionUpdatesLocalDataStore() {
    let collectionModel = ContentDetailsModelTest.Mocks.collection
    let episodeModel = collectionModel.childContents.first!
    
    let episode = Contents(context: coreDataContext)
    episode.update(from: episodeModel)
    
    let newDuration = Int64(1234)
    let newDescription = "THIS IS A DESCRIPTION"
    XCTAssertNotEqual(newDuration, episode.duration)
    XCTAssertNotEqual(newDescription, episode.desc)
    
    // Update the CD model
    episode.duration = newDuration
    episode.desc = newDescription
    try! coreDataContext.save()
    
    // Check that we persisted the values to CD correctly
    XCTAssertEqual(newDuration, episode.duration)
    XCTAssertEqual(newDescription, episode.desc)
    
    // We only have one item of content
    XCTAssertEqual(1, getAllContents().count)
    
    // Now execute the download request
    downloadService.requestDownload(content: collectionModel)
    
    // Added the correct number of models
    XCTAssertEqual(collectionModel.childContents.count + 1, getAllContents().count)
    
    // And that the values have been updated in CD appropriately
    XCTAssertEqual(Int64(episodeModel.duration), episode.duration)
    XCTAssertEqual(episodeModel.desc, episode.desc)
  }
  
  func testRequestDownloadAddsDownloadToEpisodes() {
    let collection = ContentDetailsModelTest.Mocks.collection
    let episode = collection.childContents.first!
    downloadService.requestDownload(content: episode)
    
    XCTAssertEqual(1, getAllDownloads().count)
    let download = getAllDownloads().first!
    XCTAssertEqual(Int64(episode.id), download.content?.id)
  }
  
  func testRequestDownloadAddsDownloadToScreencasts() {
    let screencast = ContentDetailsModelTest.Mocks.screencast
    downloadService.requestDownload(content: screencast)
    
    XCTAssertEqual(1, getAllDownloads().count)
    let download = getAllDownloads().first!
    XCTAssertEqual(Int64(screencast.id), download.content?.id)
  }
  
  func testRequestDownloadAddsDownloadToCollection() {
    let collection = ContentDetailsModelTest.Mocks.collection
    downloadService.requestDownload(content: collection)
    
    // Adds downloads to the collection and the individual episodes
    XCTAssertEqual(collection.childContents.count + 1, getAllDownloads().count)
    XCTAssertEqual((collection.childContents.map { $0.id } + [collection.id]) .sorted() , getAllDownloads().map { Int($0.content!.id) }.sorted())
  }
  
  func testRequestDownloadAddsDownloadInPendingState() {
    let screencast = ContentDetailsModelTest.Mocks.screencast
    downloadService.requestDownload(content: screencast)
    
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
    downloadService = DownloadService(coreDataStack: coreDataStack, userModelController: userModelController, videosServiceProvider: { _ in self.videoService })
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenLogsOut() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = .none
    userModelController.objectWillChange.send()
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenUserDoesNotHaveDownloadPermission() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = UserModel.noPermissions
    downloadService = DownloadService(coreDataStack: coreDataStack, userModelController: userModelController, videosServiceProvider: { _ in self.videoService })
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testEmptiesDownloadsDirectoryWhenPermissionsChange() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = UserModel.noPermissions
    userModelController.objectWillChange.send()
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
  }
  
  func testDoesNotEmptyDownloadDirectoryIfUserHasDownloadPermission() {
    let fileManager = FileManager.default
    let sampleFile = createSampleFile(fileManager: fileManager)
    
    userModelController.user = UserModel.withDownloads
    userModelController.objectWillChange.send()
    
    XCTAssert(fileManager.fileExists(atPath: sampleFile.path))
  }
  
  //: requestDownloadUrl() Tests
  func testRequestDownloadUrlRequestsDownloadURLForEpisode() {
    let collection = ContentDetailsModelTest.Mocks.collection
    let episode = collection.childContents.first!
    downloadService.requestDownload(content: episode)
    
    let download = getAllDownloads().first!
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlRequestsDownloadsURLForScreencast() {
    let download = sampleDownload()
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertEqual(1, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlDoesNothingForCollection() {
    let collection = ContentDetailsModelTest.Mocks.collection
    downloadService.requestDownload(content: collection)
    
    let download = getAllDownloads().first { $0.content?.contentType == "collection" }
    
    XCTAssertNotNil(download)
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(download!)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlDoesNothingForDownloadInWrongState() {
    let download = sampleDownload()
    
    download.state = .urlRequested
    
    try! coreDataContext.save()
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertEqual(0, videoService.getVideoDownloadCount)
  }
  
  func testRequestDownloadUrlUpdatesDownloadInCallback() {
    let download = sampleDownload()
    
    XCTAssertNil(download.remoteUrl)
    XCTAssertNil(download.lastValidated)
    XCTAssertEqual(Download.State.pending, download.state)
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertNotNil(download.remoteUrl)
    XCTAssertNotNil(download.lastValidated)
  }
  
  func testRequestDownloadUrlRespectsTheUserPreferencesOnQuality() {
    let download = sampleDownload()
    let attachment = AttachmentModelTest.Mocks.downloads.first { $0.kind == .sdVideoFile }!
    
    UserDefaults.standard.set(AttachmentKind.sdVideoFile.rawValue, forKey: UserDefaultsKey.downloadQuality.rawValue)
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertNotNil(download.remoteUrl)
    XCTAssertEqual(attachment.url, download.remoteUrl)
    
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.downloadQuality.rawValue)
  }
  
  func testRequestDownloadDefaultsToHDQuality() {
    UserDefaults.standard.removeObject(forKey: UserDefaultsKey.downloadQuality.rawValue)
    
    let download = sampleDownload()
    let attachment = AttachmentModelTest.Mocks.downloads.first { $0.kind == .hdVideoFile }!
    
    downloadService.requestDownloadUrl(download)
    
    XCTAssertNotNil(download.remoteUrl)
    XCTAssertEqual(attachment.url, download.remoteUrl)
  }
  
  func testRequestDownloadUpdatesTheStateCorrectly() {
    let download = sampleDownload()

    downloadService.requestDownloadUrl(download)
    
    XCTAssertEqual(Download.State.urlRequested, download.state)
  }
  
  func testEnqueueSetsPropertiesCorrectly() {
    let download = sampleDownload()
    
    // Update to include the URL
    download.remoteUrl = URL(string: "https://example.com/video.mp4")
    download.state = .urlRequested
    try! coreDataContext.save()
    
    downloadService.enqueue(download: download)
    
    XCTAssertNotNil(download.localUrl)
    XCTAssertNotNil(download.fileName)
    XCTAssertEqual(Download.State.enqueued, download.state)
  }
  
  func testEnqueueUpdatesStateToCompletedIfItFindsDownload() {
    let download = sampleDownload()
    download.remoteUrl = URL(string: "https://example.com/amazing.mp4")
    download.fileName = "\(download.content!.videoID).mp4"
    download.state = .urlRequested
    try! coreDataContext.save()
    
    let fileManager = FileManager.default
    let documentsDirectories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = documentsDirectories.first
    let downloadsDirectory = documentsDirectory!.appendingPathComponent("downloads", isDirectory: true)
    
    let sampleFile = downloadsDirectory.appendingPathComponent(download.fileName!)
    
    XCTAssert(!fileManager.fileExists(atPath: sampleFile.path))
    
    fileManager.createFile(atPath: sampleFile.path, contents: nil)

    XCTAssert(fileManager.fileExists(atPath: sampleFile.path))
    
    downloadService.enqueue(download: download)
    
    XCTAssertEqual(Download.State.complete, download.state)
    XCTAssertEqual(sampleFile, download.localUrl)
    
    try! fileManager.removeItem(at: sampleFile)
  }
  
  func testEnqueueDoesNothingForADownloadWithoutARemoteUrl() {
    let download = sampleDownload()
    download.state = .urlRequested
    try! coreDataContext.save()
    
    downloadService.enqueue(download: download)
    
    XCTAssertNil(download.fileName)
    XCTAssertNil(download.localUrl)
    XCTAssertEqual(Download.State.urlRequested ,download.state)
  }
  
  func testEnqueueDoesNothingForDownloadInTheWrongState() {
    let download = sampleDownload()
    download.remoteUrl = URL(string: "https://example.com/amazing.mp4")
    download.state = .pending
    try! coreDataContext.save()
    
    downloadService.enqueue(download: download)
    
    XCTAssertNil(download.fileName)
    XCTAssertNil(download.localUrl)
    XCTAssertEqual(Download.State.pending ,download.state)
  }
}
