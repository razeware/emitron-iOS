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

final class DownloadService {
  private let persistenceStore: PersistenceStore
  private let userModelController: UserModelController
  private var userModelControllerSubscription: AnyCancellable?
  private let videosServiceProvider: VideosService.Provider
  private var videosService: VideosService?
  private let queueManager: DownloadQueueManager
  private let downloadProcessor = DownloadProcessor()
  private var processingSubscriptions = Set<AnyCancellable>()
  
  private var downloadQuality: Attachment.Kind {
    guard let selectedQuality = UserDefaults.standard.downloadQuality,
      let kind = Attachment.Kind(from: selectedQuality) else {
        return Attachment.Kind.hdVideoFile
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
    checkPermissions()
  }
  
  func startProcessing() {
    queueManager.pendingStream
      .sink(receiveCompletion: { completion in
        // TODO: Log
        print(completion)
      }, receiveValue: { [weak self] downloadQueueItem in
        guard let self = self, let downloadQueueItem = downloadQueueItem else { return }
        self.requestDownloadUrl(downloadQueueItem)
      })
      .store(in: &processingSubscriptions)
    
    queueManager.readyForDownloadStream
      .sink(receiveCompletion: { completion in
        // TODO: Log
        print(completion)
      }, receiveValue: { [weak self] downloadQueueItem in
        guard let self = self, let downloadQueueItem = downloadQueueItem else { return }
        self.enqueue(downloadQueueItem: downloadQueueItem)
      })
      .store(in: &processingSubscriptions)
    
    queueManager.downloadQueue
    .sink(receiveCompletion: { completion in
      // TODO: Log
      print(completion)
    }, receiveValue: { [weak self] downloadQueueItems in
      guard let self = self else { return }
      downloadQueueItems.filter { $0.download.state == .enqueued }
        .forEach { (downloadQueueItem) in
          do {
            try self.downloadProcessor.add(download: downloadQueueItem.download)
          } catch {
            // TODO: Log
            print("Problem adding download: \(error)")
            self.transitionDownload(withID: downloadQueueItem.download.id, to: .failed)
          }
      }
    })
    .store(in: &processingSubscriptions)
  }
  
  func stopProcessing() {
    processingSubscriptions.forEach { $0.cancel() }
    processingSubscriptions = []
  }
}

extension DownloadService: DownloadAction {
  func requestDownload(contentId: Int, contentLookup: @escaping ContentLookup) {
    guard videosService != nil else {
      Failure
        .fetch(from: String(describing: type(of: self)), reason: "User not allowed to request downloads")
        .log()
      return
    }
    
    guard let contentPersistableState = contentLookup(contentId) else {
      Failure
        .loadFromPersistentStore(from: String(describing: type(of: self)), reason: "Unable to locate content to persist")
        .log()
      return
    }
    
    do {
      // Let's ensure that all the relevant content is stored locally
      try persistenceStore.persistContentGraph(for: contentPersistableState, contentLookup: contentLookup)
      // Now create the appropriate download objects.
      try persistenceStore.createDownloads(for: contentPersistableState.content)
    } catch {
      Failure
        .saveToPersistentStore(from: String(describing: type(of: self)), reason: "There was a problem requesting the download: \(error)")
      .log()
    }
  }
  
  func deleteDownload(contentId: Int) {
    // TODO
    fatalError("This should have been implemented")
  }
}

extension DownloadService {
  func requestDownloadUrl(_ downloadQueueItem: PersistenceStore.DownloadQueueItem) {
    guard let videosService = videosService else {
      // TODO: Log
      print("User not allowed to request downloads")
      return
    }
    guard downloadQueueItem.download.remoteUrl == nil,
      downloadQueueItem.download.state == .pending,
      downloadQueueItem.content.contentType != .collection else {
      // TODO: Log
        print("Cannot request download URL for: \(downloadQueueItem.download)")
      return
    }
    // Find the video ID
    guard let videoId = downloadQueueItem.content.videoIdentifier,
      videoId != 0 else {
      // TODO: Log
        print("Unable to locate videoId for download: \(downloadQueueItem.download)")
      return
    }
    
    // Use the video service to request the URLs
    videosService.getVideoDownload(for: videoId) { [weak self] result in
      // Ensure we're still around
      guard let self = self else { return }
      var download = downloadQueueItem.download
      
      switch result {
      case .failure(let error):
        // TODO: Log
        print("Unable to obtain download URLs: \(error)")
      case .success(let attachments):
        download.remoteUrl = attachments.first { $0.kind == self.downloadQuality }?.url
        download.lastValidatedAt = Date()
        download.state = .readyForDownload
      }
      
      // Update the state if required
      if download.remoteUrl == nil {
        download.state = .error
      }
      
      // Commit the changes
      do {
        try self.persistenceStore.update(download: download)
      } catch {
        // TODO: Log
        print("Unable to save download URL: \(error)")
        self.transitionDownload(withID: download.id, to: .failed)
      }
    }
    
    // Move it on through the state machine
    self.transitionDownload(withID: downloadQueueItem.download.id, to: .urlRequested)
  }
  
  func enqueue(downloadQueueItem: PersistenceStore.DownloadQueueItem) {
    guard downloadQueueItem.download.remoteUrl != nil,
      downloadQueueItem.download.state == .urlRequested else {
      // TODO: Log
        print("Cannot enqueue download: \(downloadQueueItem.download)")
      return
    }
    // Find the video ID
    guard let videoId = downloadQueueItem.content.videoIdentifier else {
      // TODO: Log
      print("Unable to locate videoId for download: \(downloadQueueItem.download)")
      return
    }
    
    // Generate filename
    let filename = "\(videoId).mp4"
    let localUrl = downloadsDirectory.appendingPathComponent(filename)
    
    // Save local URL and filename
    var download = downloadQueueItem.download
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
      try persistenceStore.update(download: download)
    } catch {
      // TODO: Log
      print("Unable to enqueue download: \(error)")
    }
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
  func downloadProcessor(_ processor: DownloadProcessor, downloadModelForDownloadWithId downloadId: UUID) -> DownloadProcessorModel? {
    do {
      return try persistenceStore.download(withId: downloadId)
    } catch {
      // TODO log
      print("Error finding download: \(error)")
      return .none
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didStartDownloadWithId downloadId: UUID) {
    transitionDownload(withID: downloadId, to: .inProgress)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didUpdateProgress progress: Double) {
    do {
      try persistenceStore.updateDownload(withId: downloadId, withProgress: progress)
    } catch {
      // TODO Log
      print("Unable to update progress on download: \(error)")
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didFinishDownloadWithId downloadId: UUID) {
    transitionDownload(withID: downloadId, to: .complete)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didCancelDownloadWithId downloadId: UUID) {
    do {
      if try !persistenceStore.deleteDownload(withId: downloadId) {
        // TODO Log
        print("Unable to delete download: \(downloadId)")
      }
    } catch {
      // TODO Log
      print("Unable to delete download: \(error)")
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didPauseDownloadWithId downloadId: UUID) {
    transitionDownload(withID: downloadId, to: .paused)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didResumeDownloadWithId downloadId: UUID) {
    transitionDownload(withID: downloadId, to: .inProgress)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didFailWithError error: Error) {
    transitionDownload(withID: downloadId, to: .error)
    // TODO Logging
    print("DownloadDidFailWithError: \(error)")
  }
  
  private func transitionDownload(withID id: UUID, to state: Download.State) {
    do {
      try persistenceStore.transitionDownload(withId: id, to: state)
    } catch {
      // TODO Logging
      print("Unable to transition download: \(error)")
    }
  }
}


// MARK:- Functionality for the UI
extension DownloadService {
  func downloadList() -> AnyPublisher<[ContentSummaryState], Error> {
    persistenceStore
      .downloadList()
      .eraseToAnyPublisher()
  }
  
  func downloadedContentDetail(for contentId: Int) -> AnyPublisher<ContentDetailState?, Error> {
    persistenceStore
      .downloadDetail(contentId: contentId)
      .eraseToAnyPublisher()
  }
  
  func contentSummaries(for contentIds: [Int]) -> AnyPublisher<[ContentSummaryState], Error> {
    persistenceStore
      .downloadContentSummary(for: contentIds)
      .eraseToAnyPublisher()
  }
}
