/// Copyright (c) 2020 Razeware LLC
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

final class SyncEngine {
  private let persistenceStore: PersistenceStore
  private let repository: Repository
  private let bookmarksService: BookmarksService
  private let progressionsService: ProgressionsService
  private let watchStatsService: WatchStatsService
  
  private var subscriptions = Set<AnyCancellable>()
  
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
  }
}

extension SyncEngine {
  private func completionHandler() -> ((Subscribers.Completion<Error>) -> Void) {
    return { (completion) in
      switch completion {
      case .finished:
        // Don't think we should ever actually arrive here...
        print("SyncEngine Request Stream finished. Didn't really expect it to.")
      case .failure(let error):
        Failure
          .loadFromPersistentStore(from: String(describing: type(of: self)), reason: "Couldn't load sync requests: \(error)")
          .log()
      }
    }
  }
  
  private func beginProcessing() {
    persistenceStore
      .syncRequestStream(for: [.createBookmark])
      .sink(receiveCompletion: completionHandler()) { self.syncBookmarkCreations(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
    .syncRequestStream(for: [.deleteBookmark])
    .sink(receiveCompletion: completionHandler()) { self.syncBookmarkDeletions(syncRequests: $0) }
    .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.markContentComplete, .updateProgress])
      .sink(receiveCompletion: completionHandler()) { self.syncProgressionUpdates(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.deleteProgression])
      .sink(receiveCompletion: completionHandler()) { self.syncProgressionDeletions(syncRequests: $0) }
      .store(in: &subscriptions)
    
    persistenceStore
      .syncRequestStream(for: [.recordWatchStats])
      .sink(receiveCompletion: completionHandler()) { self.syncWatchStats(syncRequests: $0) }
      .store(in: &subscriptions)
  }
  
  private func stopProcessing() {
    subscriptions.forEach { $0.cancel() }
    subscriptions.removeAll()
  }
}

extension SyncEngine {
  private func syncBookmarkCreations(syncRequests: [SyncRequest]) {
  }
  
  private func syncBookmarkDeletions(syncRequests: [SyncRequest]) {
    
  }
  
  private func syncWatchStats(syncRequests: [SyncRequest]) {
    
  }
  
  private func syncProgressionUpdates(syncRequests: [SyncRequest]) {
    
  }
  
  private func syncProgressionDeletions(syncRequests: [SyncRequest]) {
    
  }
}

extension SyncEngine: SyncAction {
  func createBookmark(for contentId: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.createBookmarkSyncRequest(for: contentId)
    
    // 2. Create cache update and pass to repository
    let bookmark = Bookmark(id: -1, createdAt: Date(), contentId: contentId)
    let cacheUpdate = DataCacheUpdate(bookmarks: [bookmark])
    repository.apply(update: cacheUpdate)
    
    // 3. Persist if the content has been persisted
    // TODO
  }
  
  func deleteBookmark(for contentId: Int) throws {
    guard let bookmark = repository.bookmark(for: contentId) else { return }
    
    // 1. Create / update sync request
    try persistenceStore.deleteBookmarkSyncRequest(for: contentId, bookmarkId: bookmark.id)
    
    // 2. Create cache update and pass to repository
    let cacheUpdate = DataCacheUpdate(bookmarkDeletionContentIds: [bookmark.contentId])
    repository.apply(update: cacheUpdate)
    
    // 3. Delete bookmark if it is persisted
    // TODO
  }
  
  func markContentAsComplete(contentId: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.markContentAsCompleteSyncRequest(for: contentId)
    
    // 2. Create cache update and pass to respository
    let cacheUpdate: DataCacheUpdate
    let progression: Progression
    if var p = repository.progression(for: contentId) {
      p.progress = p.target
      progression = p
    } else {
      guard let content = repository.content(for: contentId) else { return }
      progression = Progression.completed(for: content)
    }
    cacheUpdate = DataCacheUpdate(progressions: [progression])
    repository.apply(update: cacheUpdate)
    
    // 3. Update if persisted
    // TODO
  }
  
  func updateProgress(for contentId: Int, progress: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.updateProgressSyncRequest(for: contentId, progress: progress)
    
    // 2. Create cache update and pass to respository
    let cacheUpdate: DataCacheUpdate
    let progression: Progression
    if var p = repository.progression(for: contentId) {
      p.progress = progress
      progression = p
    } else {
      guard let content = repository.content(for: contentId) else { return }
      progression = Progression.withProgress(for: content, progress: progress)
    }
    cacheUpdate = DataCacheUpdate(progressions: [progression])
    repository.apply(update: cacheUpdate)
    
    // 3. Update if persisted
    // TODO
  }
  
  func removeProgress(for contentId: Int) throws {
    guard let progression = repository.progression(for: contentId) else { return }
    
    // 1. Create / update sync request
    try persistenceStore.removeProgressSyncRequest(for: contentId, progressionId: progression.id)
    
    // 2. Create cache update and pass to respository
    let cacheUpdate = DataCacheUpdate(progressionDeletionContentIds: [progression.id])
    repository.apply(update: cacheUpdate)
    
    // 3. Remove if persisted
    // TODO
  }
  
  func recordWatchStats(for contentId: Int, secondsWatched: Int) throws {
    // 1. Create / update sync request
    try persistenceStore.watchStatsSyncRequest(for: contentId, secondsWatched: secondsWatched)
  }
}
