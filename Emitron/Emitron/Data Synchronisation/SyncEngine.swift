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

final class SyncEngine {
  private let persistenceStore: PersistenceStore
  private let repository: Repository
  
  init(persistenceStore: PersistenceStore, repository: Repository) {
    self.persistenceStore = persistenceStore
    self.repository = repository
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
    persistenceStore.watchStatsSyncRequest(for: contentId, secondsWatched: secondsWatched)
  }
}
