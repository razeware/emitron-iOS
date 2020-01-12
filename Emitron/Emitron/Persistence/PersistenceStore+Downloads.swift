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
import GRDB
import GRDBCombine

// MARK: - Data reading methods for display
extension PersistenceStore {
  /// List of all downloads
  func downloadList() -> DatabasePublishers.Value<[ContentSummaryState]> {
    ValueObservation.tracking { db -> [ContentSummaryState] in
      let request = Content
        .including(required: Content.download)
        .including(all: Content.domains)
        .including(all: Content.categories)
        .including(optional: Content.parentContent)
        
      return try ContentSummaryState.fetchAll(db, request)
    }.publisher(in: db)
  }
}

extension PersistenceStore {
  func downloadContentSummary(for contentId: Int) -> DatabasePublishers.Value<ContentSummaryState?> {
    ValueObservation.tracking { db -> ContentSummaryState? in
      let request = Content
        .filter(key: contentId)
        .including(all: Content.domains)
        .including(all: Content.categories)
        .including(optional: Content.parentContent)
      
      return try ContentSummaryState.fetchOne(db, request)
    }.publisher(in: db)
  }
  
  func downloadContentSummary(for contentIds: [Int]) -> DatabasePublishers.Value<[ContentSummaryState]> {
    ValueObservation.tracking { db -> [ContentSummaryState] in
      let request = Content
        .filter(keys: contentIds)
        .including(all: Content.domains)
        .including(all: Content.categories)
        .including(optional: Content.parentContent)
      
      return try ContentSummaryState.fetchAll(db, request)
    }.publisher(in: db)
  }
}

extension PersistenceStore {
  func downloads(for contentIds: [Int]) -> DatabasePublishers.Value<[Download]> {
    ValueObservation.tracking { db -> [Download] in
      let request = Download
        .filter(contentIds.contains(Download.Columns.contentId))
      return try Download.fetchAll(db, request)
    }.publisher(in: db)
  }
  
  func download(for contentId: Int) -> DatabasePublishers.Value<Download?> {
    ValueObservation.tracking { db -> Download? in
      let request = Download
        .filter(Download.Columns.contentId == contentId)
      return try Download.fetchOne(db, request)
    }.publisher(in: db)
    }
}

// MARK: - Data reading methods for download queue management
extension PersistenceStore {
  /// Data required for operation of the download queue
  struct DownloadQueueItem: Decodable, FetchableRecord, Equatable {
    let download: Download
    let content: Content
  }
  /// Returns a publisher of all downloads in a given state
  /// - Parameter state: The `Download.State` to filter the results by
  func downloads(in state: Download.State) -> DatabasePublishers.Value<DownloadQueueItem?> {
    ValueObservation.tracking { db -> DownloadQueueItem? in
      let request = Download
        .all()
        .including(required: Download.content)
        .filter(state: state)
        .orderByRequestedAt()
      return try DownloadQueueItem.fetchOne(db, request)
    }.removeDuplicates().publisher(in: db)
  }
  
  /// Returns a pubisher representing the download queue over time
  /// - Parameter max: The maximum length of the queue
  func downloadQueue(withMaxLength max: Int) -> DatabasePublishers.Value<[DownloadQueueItem]> {
    ValueObservation.tracking { db -> [DownloadQueueItem] in
      let states = [Download.State.inProgress, Download.State.enqueued].map { $0.rawValue }
      let request = Download
        .including(required: Download.content)
        .filter(states.contains(Download.Columns.state))
        .order(Download.Columns.state.desc, Download.Columns.requestedAt.asc)
        .limit(max)
      return try DownloadQueueItem.fetchAll(db, request)
    }.publisher(in: db)
  }
  
  /// Return a single `Download` from its id
  /// - Parameter id: The UUID of the download to find
  func download(withId id: UUID) throws -> Download? {
    try db.read { db in
      try Download.fetchOne(db, key: id)
    }
  }
  
  
  /// Return a single `Download` from its content id
  /// - Parameter contentId: The ID of the item of content this download refers to
  func download(forContentId contentId: Int) throws -> Download? {
    try db.read { db in
      try Download
        .filter(Download.Columns.contentId == contentId)
        .fetchOne(db)
    }
  }
}

// MARK: - Data writing methods
extension PersistenceStore {
  /// Move the specified download to a new state in the download queue state machine
  /// - Parameters:
  ///   - id: The UUID of the download to transition
  ///   - state: The new `Download.State` to transition to.
  func transitionDownload(withId id: UUID, to state: Download.State) throws {
    try db.write { db in
      if var download = try Download.fetchOne(db, key: id) {
        try download.updateChanges(db) {
          $0.state = state
        }
      }
    }
  }
  
  /// Update the progress of a download
  /// - Parameters:
  ///   - id: The UUID of the download to update
  ///   - progress: The new value of progress (0–1)
  func updateDownload(withId id: UUID, withProgress progress: Double) throws {
    try db.write { db in
      if var download = try Download.fetchOne(db, key: id) {
        try download.updateChanges(db) {
          $0.progress = progress
        }
      }
    }
  }
  
  /// Save the changes to the already persisted Download object
  /// - Parameter download: The download object to save. It should already exist
  func update(download: Download) throws {
    try db.write { db in
      try download.update(db)
    }
  }
  
  /// Delete a download
  /// - Parameter id: The UUID of the download to delete
  func deleteDownload(withId id: UUID) throws -> Bool {
    try db.write { db in
      try Download.deleteOne(db, key: id)
    }
  }
  
  /// Save the entire graph of models to supprt this ContentDeailsModel
  /// - Parameter contentPersistableState: The model to persist—from the DataCache.
  func persistContentGraph(for contentPersistableState: ContentPersistableState, contentLookup: ContentLookup? = nil) throws {
    try db.write { db in
      try persistContentItem(for: contentPersistableState, inDatabase: db, withChildren: true, withParent: true, contentLookup: contentLookup)
    }
  }
  
  func createDownloads(for content: Content) throws {
    try db.write { db in
      // Create it for this content item
      try createDownload(for: content, inDatabase: db)
      
      // And now for any children that might exist
      let childContent = try content.childContents.fetchAll(db)
      try childContent.forEach { contentItem in
        try createDownload(for: contentItem, inDatabase: db)
      }
    }
  }
  
  func createDownload(for content: Content, inDatabase db: Database) throws {
    // Check whether this already exists
    if try content.download.fetchCount(db) > 0 {
      return
    }
    // Create and save the Download
    var download = Download.create(for: content)
    try download.insert(db)
  }
}

// MARK: - Private data writing methods
extension PersistenceStore {
  /// Save a content item, optionally including it's parent and children
  /// - Parameters:
  ///   - contentDetailState: The ContentDetailState to persist
  ///   - db: A `Database` object to save it
  private func persistContentItem(for contentPersistableState: ContentPersistableState, inDatabase db: Database, withChildren: Bool = false, withParent: Bool = false, contentLookup: ContentLookup? = nil) throws {
    
    // 1. Need to do parent first—we need foreign key
    //    contraints on the groupId for child content
    if withParent,
      let parentContent = contentPersistableState.parentContent,
      let contentLookup = contentLookup,
      let parentPersistable = contentLookup(parentContent.id) {
      try persistContentItem(for: parentPersistable, inDatabase: db, withChildren: true, contentLookup: contentLookup)
    }
    
    // 2. Generate and save this content item
    try contentPersistableState.content.save(db)
    
    // 3. Groups
    try contentPersistableState.groups.forEach { try $0.save(db) }
    
    // 4. Children
    if withChildren, let contentLookup = contentLookup {
      try contentPersistableState.childContents.forEach { content in
        if let childPersistable = contentLookup(content.id) {
          try persistContentItem(for: childPersistable, inDatabase: db)
        }
      }
    }
    
    // 5. Domains
    for var contentDomain in contentPersistableState.contentDomains {
      try contentDomain.save(db)
    }
    
    // 6. Categories
    for var contentCategory in contentPersistableState.contentCategories {
      try contentCategory.save(db)
    }
    
    // 7. Bookmark
    try contentPersistableState.bookmark?.save(db)
    
    // 8. Progression
    try contentPersistableState.progression?.save(db)
  }
}
