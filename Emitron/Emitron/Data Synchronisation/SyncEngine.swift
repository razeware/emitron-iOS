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

import struct Foundation.Date
import Combine
import Network

final class SyncEngine {
  private let persistenceStore: PersistenceStore
  private let repository: Repository
  private let bookmarksService: BookmarksService
  private let progressionsService: ProgressionsService
  private let watchStatsService: WatchStatsService
  
  private var subscriptions = Set<AnyCancellable>()
  private let networkMonitor = NWPathMonitor()
  
  init(
    persistenceStore: PersistenceStore,
    repository: Repository,
    bookmarksService: BookmarksService,
    progressionsService: ProgressionsService,
    watchStatsService: WatchStatsService
  ) {
    self.persistenceStore = persistenceStore
    self.repository = repository
    self.bookmarksService = bookmarksService
    self.progressionsService = progressionsService
    self.watchStatsService = watchStatsService
    
    configureNetworkObservation()
  }
}

extension SyncEngine {
  private func configureNetworkObservation() {
    networkMonitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      
      if path.status == .satisfied {
        self.beginProcessing()
      } else {
        self.stopProcessing()
      }
    }
    networkMonitor.start(queue: .global(qos: .utility))
  }
  
  private var completionHandler: (Subscribers.Completion<Error>) -> Void {
    { completion in
      switch completion {
      case .finished:
        // Don't think we should ever actually arrive here...
        print("SyncEngine Request Stream finished. Didn't really expect it to.")
      case .failure(let error):
        Failure
          .loadFromPersistentStore(from: Self.self, reason: "Couldn't load sync requests: \(error)")
          .log()
      }
    }
  }
  
  private func beginProcessing() {
    if !progressionsService.isAuthenticated {
      Event
        .syncEngine(action: "BeginProcessing::Skipping due to lack of authentication")
        .log()
      return
    }
    
    Event
      .syncEngine(action: "BeginProcessing")
      .log()
    
    persistenceStore
      .syncRequestStream(for: [.createBookmark])
      .removeDuplicates()
      .sink(receiveCompletion: completionHandler) { [weak self] in self?.syncBookmarkCreations(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.deleteBookmark])
      .removeDuplicates()
      .sink(receiveCompletion: completionHandler) { [weak self] in self?.syncBookmarkDeletions(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.markContentComplete, .updateProgress])
      .removeDuplicates()
      .sink(receiveCompletion: completionHandler) { [weak self] in self?.syncProgressionUpdates(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.deleteProgression])
      .removeDuplicates()
      .sink(receiveCompletion: completionHandler) { [weak self] in self?.syncProgressionDeletions(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.recordWatchStats])
      .removeDuplicates()
      .sink(receiveCompletion: completionHandler) { [weak self] in self?.syncWatchStats(syncRequests: $0) }
      .store(in: &subscriptions)
  }
  
  private func stopProcessing() {
    Event
      .syncEngine(action: "StopProcessing")
      .log()
    
    subscriptions.forEach { $0.cancel() }
    subscriptions.removeAll()
  }
}

extension SyncEngine {
  private func syncBookmarkCreations(syncRequests: [SyncRequest]) {
    guard !syncRequests.isEmpty else { return }
    
    Event
      .syncEngine(action: "SyncingBookmarkCreations")
      .log()
    
    syncRequests.forEach { syncRequest in
      guard syncRequest.type == .createBookmark else { return }

      Task {
        do {
          let bookmark = try await bookmarksService.makeBookmark(for: syncRequest.contentID)
          // Update the cache
          let cacheUpdate = DataCacheUpdate(bookmarks: [bookmark])
          self.repository.apply(update: cacheUpdate)
          // Remove the sync request—we're done
          self.persistenceStore.complete(syncRequests: [syncRequest])
        } catch {
          Failure
            .fetch(from: Self.self, reason: "syncBookmarkCreations:: \(error.localizedDescription)")
            .log()
        }
      }
    }
  }
  
  private func syncBookmarkDeletions(syncRequests: [SyncRequest]) {
    guard !syncRequests.isEmpty else { return }
    
    Event
      .syncEngine(action: "SyncingBookmarkDeletions")
      .log()
    
    syncRequests.forEach { syncRequest in
      guard
        case .deleteBookmark = syncRequest.type,
        let bookmarkID = syncRequest.associatedRecordID
      else { return }

      Task {
        do {
          try await bookmarksService.destroyBookmark(for: bookmarkID)
          // Update the cache
          let cacheUpdate = DataCacheUpdate(bookmarkDeletionContentIDs: [syncRequest.contentID])
          self.repository.apply(update: cacheUpdate)
          // Remove the sync request—we're done
          self.persistenceStore.complete(syncRequests: [syncRequest])
        } catch {
          Failure
            .fetch(from: Self.self, reason: "syncBookmarkDeletions:: \(error.localizedDescription)")
            .log()
          if case RWAPIError.requestFailed(_, 404) = error {
            // Remove the sync request—a 404 means it doesn't exist on the server
            self.persistenceStore.complete(syncRequests: [syncRequest])
          }
        }
      }
    }
  }
  
  private func syncWatchStats(syncRequests: [SyncRequest]) {
    guard !syncRequests.isEmpty else { return }
    
    Event
      .syncEngine(action: "SyncingWatchStats")
      .log()
    
    let watchStatRequests = syncRequests.filter {
      $0.type == .recordWatchStats
    }
    
    if watchStatRequests.isEmpty {
      return
    }
    
    Task {
      do {
        try await watchStatsService.update(watchStats: watchStatRequests)
        // Remove the sync requests—we're done
        self.persistenceStore.complete(syncRequests: watchStatRequests)
      } catch {
        Failure
          .fetch(from: Self.self, reason: "syncWatchStats:: \(error.localizedDescription)")
          .log()
      }
    }
  }
  
  private func syncProgressionUpdates(syncRequests: [SyncRequest]) {
    guard !syncRequests.isEmpty else { return }
    
    Event
      .syncEngine(action: "SyncingProgressionUpdates")
      .log()
    
    let progressionUpdates = syncRequests.filter {
      [.updateProgress, .markContentComplete].contains($0.type)
    }
    
    if progressionUpdates.isEmpty {
      return
    }

    Task {
      do {
        // Update the cache
        repository.apply(
          update: try await progressionsService.update(progressions: progressionUpdates).cacheUpdate
        )
        // Remove the sync request—we're done
        persistenceStore.complete(syncRequests: progressionUpdates)
      } catch {
        Failure
          .fetch(from: Self.self, reason: "syncProgressionUpdates:: \(error.localizedDescription)")
          .log()
      }
    }
  }
  
  private func syncProgressionDeletions(syncRequests: [SyncRequest]) {
    guard !syncRequests.isEmpty else { return }
    
    Event
      .syncEngine(action: "SyncingProgressionDeletions")
      .log()
    
    syncRequests.forEach { syncRequest in
      guard
        case .deleteProgression = syncRequest.type,
        let progressionID = syncRequest.associatedRecordID
      else { return }

      Task {
        do {
          try await progressionsService.delete(with: progressionID)
          let cacheUpdate = DataCacheUpdate(progressionDeletionContentIDs: [syncRequest.contentID])
          repository.apply(update: cacheUpdate)
          // Remove the sync request—we're done
          persistenceStore.complete(syncRequests: [syncRequest])
        } catch {
          Failure
            .fetch(from: Self.self, reason: "syncProgressionDeletions:: \(error.localizedDescription)")
            .log()

          if case RWAPIError.requestFailed(_, 404) = error {
            // Remove the sync request—a 404 means it doesn't exist on the server
            persistenceStore.complete(syncRequests: [syncRequest])
          }
        }
      }
    }
  }
}

extension SyncEngine: SyncAction {
  func createBookmark(for contentID: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.createBookmarkSyncRequest(for: contentID)
    
    // 2. Create cache update and pass to repository
    let bookmark = Bookmark(id: -1, createdAt: .now, contentID: contentID)
    let cacheUpdate = DataCacheUpdate(bookmarks: [bookmark])
    repository.apply(update: cacheUpdate)
    
    // 3. Persist if the content has been persisted
    // TODO: Persist if the content has been persisted
  }
  
  func deleteBookmark(for contentID: Int) throws {
    guard let bookmark = repository.bookmark(for: contentID) else { return }
    
    // 1. Create / update sync request
    try persistenceStore.deleteBookmarkSyncRequest(for: contentID, bookmarkID: bookmark.id)
    
    // 2. Create cache update and pass to repository
    let cacheUpdate = DataCacheUpdate(bookmarkDeletionContentIDs: [bookmark.contentID])
    repository.apply(update: cacheUpdate)
    
    // 3. Delete bookmark if it is persisted
    // TODO: Delete bookmark if it is persisted
  }
  
  func markContentAsComplete(contentID: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.markContentAsCompleteSyncRequest(for: contentID)
    
    // 2. Create cache update and pass to repository
    let cacheUpdate: DataCacheUpdate
    let progression: Progression
    if var existingProgression = repository.progression(for: contentID) {
      existingProgression.progress = existingProgression.target
      progression = existingProgression
    } else {
      guard let content = repository.content(for: contentID) else { return }
      progression = Progression.completed(for: content)
    }
    cacheUpdate = DataCacheUpdate(progressions: [progression])
    repository.apply(update: cacheUpdate)
    
    // 3. Update if persisted
    // TODO: Update if persisted
    
    // 4. Check whether we need to update a parent
    if let parentContent = repository.parentContent(for: contentID),
      let childProgressUpdate = repository.childProgress(for: parentContent.id),
      var existingProgression = repository.progression(for: parentContent.id) {
      existingProgression.progress = childProgressUpdate.completed
      let parentCacheUpdate = DataCacheUpdate(progressions: [existingProgression])
      repository.apply(update: parentCacheUpdate)
    }
  }
  
  func updateProgress(for contentID: Int, progress: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.updateProgressSyncRequest(for: contentID, progress: progress)
    
    // 2. Create cache update and pass to repository
    let cacheUpdate: DataCacheUpdate
    let progression: Progression
    if var existingProgression = repository.progression(for: contentID) {
      existingProgression.progress = progress
      progression = existingProgression
    } else {
      guard let content = repository.content(for: contentID) else { return }
      progression = Progression.withProgress(for: content, progress: progress)
    }
    cacheUpdate = DataCacheUpdate(progressions: [progression])
    repository.apply(update: cacheUpdate)
    
    // 3. Update if persisted
    // TODO: Update if persisted
    
    // 4. Check whether we need to update a parent
    if let parentContent = repository.parentContent(for: contentID),
      let childProgressUpdate = repository.childProgress(for: parentContent.id),
      var existingProgression = repository.progression(for: parentContent.id) {
      existingProgression.progress = childProgressUpdate.completed
      let parentCacheUpdate = DataCacheUpdate(progressions: [existingProgression])
      repository.apply(update: parentCacheUpdate)
    }
  }
  
  func removeProgress(for contentID: Int) throws {
    guard let progression = repository.progression(for: contentID) else { return }
    
    // 1. Create / update sync request
    try persistenceStore.removeProgressSyncRequest(for: contentID, progressionID: progression.id)
    
    // 2. Create cache update and pass to repository
    let cacheUpdate = DataCacheUpdate(progressionDeletionContentIDs: [contentID])
    repository.apply(update: cacheUpdate)
    
    // 3. Remove if persisted
    // TODO: Remove if persisted
    
    // 4. Check whether we need to update a parent
    if let parentContent = repository.parentContent(for: contentID),
      let childProgressUpdate = repository.childProgress(for: parentContent.id),
      var existingProgression = repository.progression(for: parentContent.id) {
      existingProgression.progress = childProgressUpdate.completed
      let parentCacheUpdate = DataCacheUpdate(progressions: [existingProgression])
      repository.apply(update: parentCacheUpdate)
    }
  }
  
  func recordWatchStats(for contentID: Int, secondsWatched: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.watchStatsSyncRequest(for: contentID, secondsWatched: secondsWatched)
  }
}
