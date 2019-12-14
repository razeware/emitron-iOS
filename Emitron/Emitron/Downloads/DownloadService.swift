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

final class DownloadService {
  private let persistenceStore: PersistenceStore
  private let userModelController: UserModelController
  private var userModelControllerSubscription: AnyCancellable?
  private let videosServiceProvider: VideosService.Provider
  private var videosService: VideosService?
  private let queueManager: DownloadQueueManager
  private let downloadProcessor = DownloadProcessor()
  private var processingSubscriptions = Set<AnyCancellable>()
  
  private var downloadQuality: AttachmentKind {
    guard let selectedQuality = UserDefaults.standard.downloadQuality,
      let kind = AttachmentKind(rawValue: selectedQuality) else {
        return AttachmentKind.hdVideoFile
    }
    return kind
  }
  private lazy var downloadsDirectory: URL = {
    let fileManager = FileManager.default
    let documentsDirectories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    guard let documentsDirectory = documentsDirectories.first else {
      fatalError("Unable to locate the documents directory")
    }
    
    return documentsDirectory.appendingPathComponent("downloads", isDirectory: true)
  }()
  
  var backgroundSessionCompletionHandler: (() -> Void)? {
    get {
      downloadProcessor.backgroundSessionCompletionHandler
    }
    set {
      downloadProcessor.backgroundSessionCompletionHandler = newValue
    }
  }
  
  init(persistenceStore: PersistenceStore, userModelController: UserModelController, videosServiceProvider: VideosService.Provider? = .none) {
    self.persistenceStore = persistenceStore
    self.userModelController = userModelController
    self.queueManager = DownloadQueueManager(persistenceStore: persistenceStore)
    self.videosServiceProvider = videosServiceProvider ?? { VideosService(client: $0) }
    self.userModelControllerSubscription = userModelController.objectWillChange.sink { [weak self] in
      guard let self = self else { return }
      self.checkPermissions()
    }
    self.downloadProcessor.delegate = self
    self.displayableDownloadsFR = FetchResults(context: coreDataStack.viewContext, request: Content.displayableDownloads)
    checkPermissions()
  }
  
  func startProcessing() {
    queueManager.pendingStream
      .sink(receiveCompletion: { completion in
        // TODO: Log
        print(completion)
      }, receiveValue: { [weak self] download in
        guard let self = self else { return }
        self.requestDownloadUrl(download)
      })
      .store(in: &processingSubscriptions)
    
    queueManager.readyForDownloadStream
      .sink(receiveCompletion: { completion in
        // TODO: Log
        print(completion)
      }, receiveValue: { [weak self] download in
        guard let self = self else { return }
        self.enqueue(download: download)
      })
      .store(in: &processingSubscriptions)
    
    queueManager.downloadQueue
    .sink(receiveCompletion: { completion in
      // TODO: Log
      print(completion)
    }, receiveValue: { [weak self] downloads in
      guard let self = self else { return }
      downloads.filter { $0.state == .enqueued }
        .forEach { (download) in
          do {
            try self.downloadProcessor.add(download: download)
          } catch {
            // TODO: Log
            print("Problem adding download: \(error)")
            download.state = .failed
            self.saveContext()
          }
      }
    })
    .store(in: &processingSubscriptions)
  }
  
  func stopProcessing() {
    processingSubscriptions.forEach { $0.cancel() }
    processingSubscriptions = []
  }
  
  func requestDownload(content: ContentDetailsModel) {
    guard videosService != nil else {
      // TODO: Log
      print("User not allowed to request downloads")
      return
    }
    // Let's ensure that all the relevant content is stored locally
    var contentToDownload = [Content]()
    contentToDownload.append(addOrUpdate(content: content))
    if let parentContent = content.parentContent {
      // If the requested content has parent content we don't
      // want to donwload it.
      let _ = addOrUpdate(content: parentContent)
    }
    // We do want to download all child content tho
    contentToDownload += content.childContents.map { addOrUpdate(content: $0) }
    
    // Now create the appropriate download objects.
    //TODO: Should we do anything with these?
    let _ = contentToDownload.map { createDownload(content: $0) }
    
    // Commit all these changes
    if coreDataStack.viewContext.hasChanges {
      do {
        try coreDataStack.viewContext.save()
      } catch {
        // TODO
        print("Unable to save. Not sure what to do.")
      }
    }
  }
}

extension DownloadService {
  func requestDownloadUrl(_ download: Download) {
    guard let videosService = videosService else {
      // TODO: Log
      print("User not allowed to request downloads")
      return
    }
    guard download.remoteUrl == nil, download.state == .pending, download.content?.contentType != "collection" else {
      // TODO: Log
      print("Cannot request download URL for: \(download)")
      return
    }
    // Find the video ID
    guard let videoId = download.content?.videoID, videoId != 0 else {
      // TODO: Log
      print("Unable to locate videoId for download: \(download)")
      return
    }
    
    // Use the video service to request the URLs
    videosService.getVideoDownload(for: Int(videoId)) { [weak self] result in
      // Ensure we're still around
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        // TODO: Log
        print("Unable to obtain download URLs: \(error)")
      case .success(let attachments):
        download.remoteUrl = attachments.first { $0.kind == self.downloadQuality }?.url
        download.lastValidated = Date()
        download.state = .readyForDownload
      }
      
      // Update the state if required
      if download.remoteUrl == nil {
        download.state = .error
      }
      
      // Commit the changes
      do {
        try self.coreDataContext.save()
      } catch {
        // TODO: Log
        print("Unable to save URL: \(error)")
      }
    }
    
    // Update the state
    download.state = .urlRequested
    // Commit the changes
    do {
      try self.coreDataContext.save()
    } catch {
      // TODO: Log
      print("Unable to request the donwload URL: \(error)")
    }
  }
  
  func enqueue(download: Download) {
    guard download.remoteUrl != nil, download.state == .urlRequested else {
      // TODO: Log
      print("Cannot enqueue download: \(download)")
      return
    }
    // Find the video ID
    guard let videoId = download.content?.videoID else {
      // TODO: Log
      print("Unable to locate videoId for download: \(download)")
      return
    }
    
    // Generate filename
    let filename = "\(videoId).mp4"
    let localUrl = downloadsDirectory.appendingPathComponent(filename)
    
    // Save local URL and filename
    download.localUrl = localUrl
    download.fileName = filename
    
    // Transition download to correct status
    // If file exists, update the download
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: localUrl.path) {
      download.state = .complete
    } else {
      download.state = .enqueued
    }
    
    // Save
    do {
      try self.coreDataContext.save()
    } catch {
      // TODO: Log
      print("Unable to enqueue download: \(error)")
    }
  }
  
  private func addOrUpdate(content model: ContentDetailsModel) -> Content {
    // Check to see whether we already have one
    let request: NSFetchRequest<Content> = Contents.fetchRequest()
    request.predicate = NSPredicate(format: "id = %d", model.id)
    
    // Get hold of or create the content record
    var content: Content?
    do {
      let contents = try coreDataContext.fetch(request)
      content = contents.first
    } catch {
      // TODO: Update this to logging.
      print(error)
    }
    if content == nil {
      content = Content(context: coreDataContext)
    }
    
    // Update the Content from the ContentDetailsModel
    content!.update(from: model)
    return content!
  }
  
  private func createDownload(content: Content) -> Download {
    if let download = content.download {
      // Already got a download requested
      return download
    }
    
    let download = Download(context: coreDataContext)
    download.assignDefaults()
    
    // Assign it to the appropriate content
    content.download = download
    return download
  }
  
  private func prepareDownloadDirectory() {
    let fileManager = FileManager.default
    do {
      if !fileManager.fileExists(atPath: downloadsDirectory.path) {
        try fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: false)
      }
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try downloadsDirectory.setResourceValues(values)
    } catch {
      fatalError("Unable to prepare downloads directory: \(error)")
    }
  }
  
  private func deleteExistingDownloads() {
    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: downloadsDirectory.path) {
        try fileManager.removeItem(at: downloadsDirectory)
      }
      prepareDownloadDirectory()
    } catch {
      fatalError("Unable to delete the contents of the downloads directory: \(error)")
    }
  }
  
  private func checkPermissions() {
    guard let user = userModelController.user else {
      // There's no user—delete everything
      destroyDownloads()
      videosService = .none
      return
    }
    if user.canDownload {
      // Allowed to download. Let's make a video service and the d/l dir
      prepareDownloadDirectory()
      if videosService == nil {
        videosService = videosServiceProvider(userModelController.client)
      }
    } else {
      // User doesn't have download permission. Delete everything and reset.
      destroyDownloads()
      videosService = .none
    }
  }
  
  private func destroyDownloads() {
    // This will delete the Download model records, via the delegate callback
    downloadProcessor.cancelAllDownloads()
    deleteExistingDownloads()
  }
}

extension DownloadService: DownloadProcessorDelegate {
  private func findDownload(withId id: UUID) -> Download? {
    let request = Download.findBy(id: id)
    let result = try? coreDataContext.fetch(request)
    return result?.first
  }
  
  private func saveContext() {
    do {
      try coreDataContext.save()
    } catch {
      // TODO log
      print("Unable to save: \(error)")
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadModelForDownloadWithId downloadId: UUID) -> DownloadProcessorModel? {
    return findDownload(withId: downloadId)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didStartDownloadWithId downloadId: UUID) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.state = .inProgress
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didUpdateProgress progress: Float) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.progress = progress
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didFinishDownloadWithId downloadId: UUID) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.state = .complete
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didCancelDownloadWithId downloadId: UUID) {
    guard let download = findDownload(withId: downloadId) else { return }
    coreDataContext.delete(download)
    if let content = download.content {
      coreDataContext.delete(content)
    }
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didPauseDownloadWithId downloadId: UUID) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.state = .paused
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didResumeDownloadWithId downloadId: UUID) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.state = .inProgress
    saveContext()
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didFailWithError error: Error) {
    guard let download = findDownload(withId: downloadId) else { return }
    download.state = .error
    
  }
}
