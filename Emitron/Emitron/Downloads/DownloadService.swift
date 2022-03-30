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

import Combine
import Foundation
import Network

final class DownloadService: ObservableObject {
  enum Status {
    case active
    case inactive

    init(expensive: Bool, expensiveAllowed: Bool) {
      self =
        expensive && !expensiveAllowed
        ? .inactive
        : .active
    }
  }
  
  // MARK: Properties
  private let persistenceStore: PersistenceStore
  private let userModelController: UserModelController
  private var userModelControllerSubscription: AnyCancellable?
  private let videosServiceProvider: VideosService.Provider
  private var videosService: VideosService?
  private let queueManager: DownloadQueueManager
  private let downloadProcessor: DownloadProcessor
  private var processingSubscriptions = Set<AnyCancellable>()
  
  private let networkMonitor = NWPathMonitor()
  private var status: Status = .inactive
  private var settingsSubscription: AnyCancellable?
  private var downloadQueueSubscription: AnyCancellable?
  
  private var downloadQuality: Attachment.Kind {
    settingsManager.downloadQuality
  }
  
  var backgroundSessionCompletionHandler: (() -> Void)? {
    get {
      downloadProcessor.backgroundSessionCompletionHandler
    }
    set {
      downloadProcessor.backgroundSessionCompletionHandler = newValue
    }
  }

  let settingsManager: SettingsManager
  
  // MARK: Initialisers
  init(
    persistenceStore: PersistenceStore,
    userModelController: UserModelController,
    videosServiceProvider: VideosService.Provider? = .none,
    settingsManager: SettingsManager
  ) {
    self.persistenceStore = persistenceStore
    self.userModelController = userModelController
    downloadProcessor = DownloadProcessor(settingsManager: settingsManager)
    queueManager = DownloadQueueManager(persistenceStore: persistenceStore, maxSimultaneousDownloads: 3)
    self.videosServiceProvider = videosServiceProvider ?? { VideosService(client: $0) }
    self.settingsManager = settingsManager
    userModelControllerSubscription = userModelController.objectDidChange.sink { [weak self] in
      self?.stopProcessing()
      self?.checkPermissions()
      self?.startProcessing()
    }
    downloadProcessor.delegate = self
    checkPermissions()
  }
  
  // MARK: Queue Management
  func startProcessing() {
    // Make sure that we can't start multiple processing subscriptions
    stopProcessing()
    queueManager.pendingStream
      .sink(
        receiveCompletion: { completion in
          Failure
            .repositoryLoad(from: Self.self, reason: "Error: \(completion)")
            .log()
        },
        receiveValue: { [weak self] downloadQueueItem in
          guard let self = self, let downloadQueueItem = downloadQueueItem else { return }
          self.requestDownloadURL(downloadQueueItem)
        }
      )
      .store(in: &processingSubscriptions)
    
    queueManager.readyForDownloadStream
      .sink(
        receiveCompletion: { completion in
          Failure
            .repositoryLoad(from: Self.self, reason: "Error: \(completion)")
            .log()
        },
        receiveValue: { [weak self] downloadQueueItem in
          guard let self = self, let downloadQueueItem = downloadQueueItem else { return }
          self.enqueue(downloadQueueItem: downloadQueueItem)
        }
      )
      .store(in: &processingSubscriptions)
    
    // The download queue subscription is part of the
    // network monitoring process.
    checkQueueStatus()
  }
  
  func stopProcessing() {
    processingSubscriptions.forEach { $0.cancel() }
    processingSubscriptions = []
    
    pauseQueue()
  }
}

// MARK: - DownloadAction Methods
extension DownloadService: DownloadAction {  
  func requestDownload(contentID: Int, contentLookup: @escaping ContentLookup) -> AnyPublisher<RequestDownloadResult, DownloadActionError> {
    guard videosService != nil else {
      Failure
        .fetch(from: Self.self, reason: "User not allowed to request downloads")
        .log()
      return Future { promise in
        promise(.failure(.problemRequestingDownload))
      }
      .eraseToAnyPublisher()
    }
    
    guard let contentPersistableState = contentLookup(contentID) else {
      Failure
        .loadFromPersistentStore(from: Self.self, reason: "Unable to locate content to persist")
        .log()
      return Future { promise in
        promise(.failure(.problemRequestingDownload))
      }
      .eraseToAnyPublisher()
    }
    
    // Let's ensure that all the relevant content is stored locally
    return persistenceStore.persistContentGraph(
      for: contentPersistableState,
      contentLookup: contentLookup
    )
    .flatMap {
      self.persistenceStore.createDownloads(for: contentPersistableState.content)
    }
    .map {
      switch self.status {
      case .active:
        return RequestDownloadResult.downloadRequestedSuccessfully
      case .inactive:
        return RequestDownloadResult.downloadRequestedButQueueInactive
      }
    }
    .mapError { error in
      Failure
        .saveToPersistentStore(from: Self.self, reason: "There was a problem requesting the download: \(error)")
        .log()
      return DownloadActionError.problemRequestingDownload
    }
    .eraseToAnyPublisher()
  }
  
  func cancelDownload(contentID: Int) -> AnyPublisher<Void, DownloadActionError> {
    var contentIDs = [Int]()
    
    // 0. If there are some children, then let's find their content ids too
    if let children = try? persistenceStore.childContentsForDownloadedContent(with: contentID) {
      contentIDs = children.contents.map(\.id)
    }
    contentIDs += [contentID]
    
    // 1. Find the downloads.
    let downloads = contentIDs.compactMap {
      try? persistenceStore.download(forContentID: $0)
    }
    // 2. Is it already downloading?
    let currentlyDownloading = downloads.filter(\.isDownloading)
    let notYetDownloading = downloads.filter { !$0.isDownloading }
    
    return Future<Void, Error> { promise in
      do {
        // It's in the download process, so let's ask it to cancel it.
        // The delegate callback will handle deleting the value in
        // the persistence store.
        try currentlyDownloading.forEach { try self.downloadProcessor.cancelDownload($0) }
        promise(.success(()))
      } catch {
        promise(.failure(error))
      }
    }
    .flatMap { _ in
      // Don't have it in the processor, so we just need to
      // delete the download model
      self.persistenceStore
        .deleteDownloads(withIDs: notYetDownloading.map(\.id))
    }
    .mapError { error in
      Failure
        .deleteFromPersistentStore(from: Self.self, reason: "There was a problem cancelling the download (contentID: \(contentID)): \(error)")
        .log()
      return DownloadActionError.unableToCancelDownload
    }
    .eraseToAnyPublisher()
  }
  
  func deleteDownload(contentID: Int) -> AnyPublisher<Void, DownloadActionError> {
    var contentIDs = [Int]()
    
    // 0. If there are some children, the let's find their content ids too
    if let children = try? persistenceStore.childContentsForDownloadedContent(with: contentID) {
      contentIDs = children.contents.map(\.id)
    }
    contentIDs += [contentID]
    
    // 1. Find the downloads
    let downloads = contentIDs.compactMap {
      try? persistenceStore.download(forContentID: $0)
    }
    
    return Future<Void, Error> { promise in
      do {
        // 2. Delete the file from disk
        try downloads
          .filter { $0.isDownloaded }
          .forEach(self.deleteFile)
        promise(.success(()))
      } catch {
        promise(.failure(error))
      }
    }
    .flatMap {
      // 3. Delete the persisted record
      self.persistenceStore
        .deleteDownloads(withIDs: downloads.map(\.id))
    }
    .mapError { error in
      Failure
        .deleteFromPersistentStore(from: Self.self, reason: "There was a problem deleting the download (contentID: \(contentID)): \(error)")
        .log()
      return DownloadActionError.unableToDeleteDownload
    }
    .eraseToAnyPublisher()
  }
}

// MARK: - Internal methods
extension DownloadService {
  func requestDownloadURL(_ downloadQueueItem: PersistenceStore.DownloadQueueItem) {
    guard let videosService = videosService else {
      Failure
        .downloadService(
          from: #function,
          reason: "User not allowed to request downloads."
        )
        .log()
      return
    }
    guard
      downloadQueueItem.download.remoteURL == nil,
      downloadQueueItem.download.state == .pending,
      downloadQueueItem.content.contentType != .collection
    else {
      Failure
        .downloadService(
          from: #function,
          reason: "Cannot request download URL for: \(downloadQueueItem.download)"
        )
        .log()
      return
    }
    // Find the video ID
    guard
      let videoID = downloadQueueItem.content.videoIdentifier,
      videoID != 0
    else {
      Failure
        .downloadService(
          from: #function,
          reason: "Unable to locate videoID for download: \(downloadQueueItem.download)"
        )
        .log()
      return
    }
    
    // Use the video service to request the URLs
    videosService.getVideoStreamDownload(for: videoID) { [weak self] result in
      // Ensure we're still around
      guard let self = self else { return }
      var download = downloadQueueItem.download

      switch result {
      case .failure(let error):
        Failure
          .downloadService(
            from: #function,
            reason: "Unable to obtain download URLs: \(error)"
          )
          .log()
      case .success(let attachment):
        download.remoteURL = attachment.url
        download.lastValidatedAt = .now
        download.state = .readyForDownload
      }

      // Update the state if required
      if download.remoteURL == nil {
        download.state = .error
      }

      // Commit the changes
      do {
        try self.persistenceStore.update(download: download)
      } catch {
        Failure
          .downloadService(
            from: #function,
            reason: "Unable to save download URL: \(error)"
          )
          .log()
        self.transitionDownload(withID: download.id, to: .failed)
      }
    }
    // Move it on through the state machine
    transitionDownload(withID: downloadQueueItem.download.id, to: .urlRequested)
  }
  
  func enqueue(downloadQueueItem: PersistenceStore.DownloadQueueItem) {
    guard
      downloadQueueItem.download.remoteURL != nil,
      downloadQueueItem.download.state == .readyForDownload
    else {
      Failure
        .downloadService(
          from: #function,
          reason: "Cannot enqueue download: \(downloadQueueItem.download)"
        )
        .log()
      return
    }
    // Find the video ID
    guard let videoID = downloadQueueItem.content.videoIdentifier else {
      Failure
        .downloadService(
          from: #function,
          reason: "Unable to locate videoID for download: \(downloadQueueItem.download)"
        )
        .log()
      return
    }
    
    // Generate filename
    let filename = "\(videoID).m3u8"
    
    // Save local URL and filename
    var download = downloadQueueItem.download
    download.fileName = filename
    
    // Transition download to correct status
    // If file exists, update the download
    if let localURL = download.localURL, FileManager.default.fileExists(atPath: localURL.path) {
      download.state = .complete
    } else {
      download.state = .enqueued
    }
    
    // Save
    do {
      try persistenceStore.update(download: download)
    } catch {
      Failure
        .saveToPersistentStore(from: Self.self, reason: "Unable to enqueue download: \(error)")
        .log()
    }
  }
  
  private func prepareDownloadDirectory() {
    let fileManager = FileManager.default
    do {
      if !fileManager.fileExists(atPath: URL.downloadsDirectory.path) {
        try fileManager.createDirectory(at: .downloadsDirectory, withIntermediateDirectories: false)
      }
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      var downloadsDirectory = URL.downloadsDirectory
      try downloadsDirectory.setResourceValues(values)
      #if DEBUG
        print("Download directory located at: \(URL.downloadsDirectory.path)")
      #endif
    } catch {
      preconditionFailure("Unable to prepare downloads directory: \(error)")
    }
  }
  
  private func deleteExistingDownloads() {
    do {
      try FileManager.removeExistingFile(at: .downloadsDirectory)
      prepareDownloadDirectory()
    } catch {
      preconditionFailure("Unable to delete the contents of the downloads directory: \(error)")
    }
    do {
      try persistenceStore.erase()
    } catch {
      Failure
        .deleteFromPersistentStore(from: Self.self, reason: "Unable to destroy all downloads")
        .log()
    }
  }
  
  private func deleteFile(for download: Download) throws {
    guard let localURL = download.localURL else { return }
    try FileManager.removeExistingFile(at: localURL)
  }
  
  private func checkPermissions() {
    guard let user = userModelController.user else {
      // There's no user—delete everything
      stopProcessing()
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
      stopProcessing()
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

// MARK: - DownloadProcesserDelegate Methods
extension DownloadService: DownloadProcessorDelegate {
  func downloadProcessor(_ processor: DownloadProcessor, downloadModelForDownloadWithID downloadID: UUID) -> DownloadProcessorModel? {
    do {
      return try persistenceStore.download(withID: downloadID)
    } catch {
      Failure
        .loadFromPersistentStore(from: Self.self, reason: "Error finding download: \(error)")
        .log()
      return .none
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didStartDownloadWithID downloadID: UUID) {
    transitionDownload(withID: downloadID, to: .inProgress)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithID downloadID: UUID, didUpdateProgress progress: Double) {
    do {
      try persistenceStore.updateDownload(withID: downloadID, withProgress: progress)
    } catch {
      Failure
        .saveToPersistentStore(from: Self.self, reason: "Unable to update progress on download: \(error)")
        .log()
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didFinishDownloadWithID downloadID: UUID) {
    transitionDownload(withID: downloadID, to: .complete)
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, didCancelDownloadWithID downloadID: UUID) {
    do {
      if try !persistenceStore.deleteDownload(withID: downloadID) {
        Failure
          .deleteFromPersistentStore(from: Self.self, reason: "Unable to delete download: \(downloadID)")
          .log()
      }
    } catch {
      Failure
        .deleteFromPersistentStore(from: Self.self, reason: "Unable to delete download: \(error)")
        .log()
    }
  }
  
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithID downloadID: UUID, didFailWithError error: Error) {
    transitionDownload(withID: downloadID, to: .error)
    Failure
      .saveToPersistentStore(from: Self.self, reason: "DownloadDidFailWithError: \(error)")
      .log()
  }
  
  private func transitionDownload(withID id: UUID, to state: Download.State) {
    do {
      try persistenceStore.transitionDownload(withID: id, to: state)
    } catch {
      Failure
        .saveToPersistentStore(from: Self.self, reason: "Unable to transition download: \(error)")
        .log()
    }
  }
}

// MARK: - Functionality for the UI
extension DownloadService {
  func downloadList() -> AnyPublisher<[ContentSummaryState], Error> {
    persistenceStore
      .downloadList()
      .eraseToAnyPublisher()
  }
}

// MARK: - Wifi Status Handling
extension DownloadService {
  private func configureWifiObservation() {
    // Track the network status
    networkMonitor.pathUpdateHandler = { [weak self] _ in
      self?.checkQueueStatus()
    }
    networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    
    // Track the status of the wifi downloads setting
    settingsSubscription = settingsManager
      .wifiOnlyDownloadsPublisher
      .removeDuplicates()
      .sink(receiveValue: { [weak self] _ in
        self?.checkQueueStatus()
      })
  }
  
  private func checkQueueStatus() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      let expensive = self.networkMonitor.currentPath.isExpensive
      let allowedExpensive = self.settingsManager.wifiOnlyDownloads
      self.status = .init(expensive: expensive, expensiveAllowed: allowedExpensive)
      
      switch self.status {
      case .active:
        self.resumeQueue()
      case .inactive:
        self.pauseQueue()
      }
    }
  }
  
  private func pauseQueue() {
    // Cancel download queue processing
    downloadQueueSubscription?.cancel()
    downloadQueueSubscription = nil
    
    // Pause all downloads already in the processor
    downloadProcessor.pauseAllDownloads()
  }
  
  private func resumeQueue() {
    // Don't do anything if we already have a subscription
    guard downloadQueueSubscription == nil else { return }
    
    // Start download queue processing
    downloadQueueSubscription = queueManager.downloadQueue
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            print("Should never get here.... \(completion)")
          case .failure(let error):
            Failure
              .downloadService(from: Self.self, reason: "DownloadQueue: \(error)")
              .log()
          }
        },
        receiveValue: { [weak self] downloadQueueItems in
          guard let self = self else { return }
          downloadQueueItems.filter { $0.download.state == .enqueued }
            .forEach { downloadQueueItem in
              do {
                try self.downloadProcessor.add(download: downloadQueueItem.download)
              } catch {
                Failure
                  .downloadService(from: Self.self, reason: "Problem adding download: \(error)")
                  .log()
                self.transitionDownload(withID: downloadQueueItem.download.id, to: .failed)
              }
            }
        }
      )
    
    // Resume all downloads that the processor is already working on
    downloadProcessor.resumeAllDownloads()
  }
}
