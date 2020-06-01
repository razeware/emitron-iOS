// Copyright (c) 2019 Razeware LLC
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
import struct Foundation.UUID
import GRDB
import GRDBCombine

// MARK: - Data reading methods for display
extension PersistenceStore {
  /// List of all downloads
  func downloadList() -> DatabasePublishers.Value<[ContentSummaryState]> {
    ValueObservation.tracking { db -> [ContentSummaryState] in
      let contentTypes = [ContentType.collection, ContentType.screencast].map(\.rawValue)
      let request = Content
        .filter(contentTypes.contains(Content.Columns.contentType))
        .including(required: Content.download)
        .including(all: Content.domains)
        .including(all: Content.categories)
        
      return try ContentSummaryState.fetchAll(db, request)
    }
    .removeDuplicates()
    .publisher(in: db)
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
    }
    .publisher(in: db)
  }
  
  func downloadContentSummary(for contentIds: [Int]) -> DatabasePublishers.Value<[ContentSummaryState]> {
    ValueObservation.tracking { db -> [ContentSummaryState] in
      let request = Content
        .filter(keys: contentIds)
        .including(all: Content.domains)
        .including(all: Content.categories)
        .including(optional: Content.parentContent)
      
      return try ContentSummaryState.fetchAll(db, request)
    }
    .publisher(in: db)
  }
}

extension PersistenceStore {
  func downloads(for contentIds: [Int]) -> DatabasePublishers.Value<[Download]> {
    ValueObservation.tracking { db -> [Download] in
      let request = Download
        .filter(contentIds.contains(Download.Columns.contentId))
      return try Download.fetchAll(db, request)
    }
    .publisher(in: db)
  }
  
  func download(for contentId: Int) -> DatabasePublishers.Value<Download?> {
    ValueObservation.tracking { db -> Download? in
      let request = Download
        .filter(Download.Columns.contentId == contentId)
      return try Download.fetchOne(db, request)
    }
    .publisher(in: db)
  }
}

extension PersistenceStore {
  struct ChildContentContainer: Decodable, FetchableRecord {
    let contents: [Content]
  }
  
  func childContentsForDownloadedContent(with id: Int) throws -> ChildContentsState? {
    try db.read { db in
      let contentRequest = Content
        .filter(key: id)
        .including(all: Content.childContents)
      guard let contents = try ChildContentContainer.fetchOne(db, contentRequest) else { return nil }
      let groups = try Group
        .filter(Group.Columns.contentId == id)
        .fetchAll(db)
      return ChildContentsState(contents: contents.contents, groups: groups)
    }
  }
  
  func downloadedContent(with id: Int) throws -> Content? {
    try db.read { db in
      try Content.fetchOne(db, key: id)
    }
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
      let contentTypes = [ContentType.episode, ContentType.screencast].map(\.rawValue)
      let contentAlias = TableAlias()
      let request = Download
        .all()
        .including(required: Download.content.aliased(contentAlias))
        .filter(contentTypes.contains(contentAlias[Content.Columns.contentType]))
        .filter(state: state)
        .orderByRequestedAtAndOrdinal()
      return try DownloadQueueItem.fetchOne(db, request)
    }
    .removeDuplicates()
    .publisher(in: db)
  }
  
  /// Returns a pubisher representing the download queue over time
  /// - Parameter max: The maximum length of the queue
  func downloadQueue(withMaxLength max: Int) -> DatabasePublishers.Value<[DownloadQueueItem]> {
    ValueObservation.tracking { db -> [DownloadQueueItem] in
      let states = [Download.State.inProgress, Download.State.enqueued].map(\.rawValue)
      let contentTypes = [ContentType.episode, ContentType.screencast].map(\.rawValue)
      let contentAlias = TableAlias()
      let request = Download
        .including(required: Download.content.aliased(contentAlias))
        .filter(states.contains(Download.Columns.state))
        .filter(contentTypes.contains(contentAlias[Content.Columns.contentType]))
        .order(Download.Columns.state.desc, Download.Columns.requestedAt.asc, Download.Columns.ordinal.asc)
        .limit(max)
      return try DownloadQueueItem.fetchAll(db, request)
    }
    .removeDuplicates()
    .publisher(in: db)
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
  
  /// Used to determine the state of the `Download` for a collection
  struct CollectionDownloadSummary: Equatable {
    let totalChildren: Int
    let childrenRequested: Int
    let childrenCompleted: Int
    
    var state: Download.State {
      if childrenRequested == childrenCompleted && childrenCompleted == totalChildren {
        return .complete
      }
      if childrenCompleted < childrenRequested {
        return .inProgress
      }
      if childrenRequested > 0 {
        return .paused
      }
      return .pending
    }
    
    var progress: Double {
      Double(childrenCompleted) / Double(childrenRequested)
    }
  }
  
  /// Summary download stats for the children of the given collection
  /// - Parameter contentId: ID representing an item of `Content` with `ContentType` of `.collection`
  func collectionDownloadSummary(forContentId contentId: Int) throws -> CollectionDownloadSummary {
    try db.read { db in
      guard let content = try Content.fetchOne(db, key: contentId),
        content.contentType == .collection else {
          throw PersistenceStoreError.argumentError
      }
      
      let totalChildren = try content.childContents.fetchCount(db)
      let totalChildDownloads = try content.childDownloads.fetchCount(db)
      let totalCompletedChildDownloads = try content.childDownloads.filter(Download.Columns.state == Download.State.complete.rawValue).fetchCount(db)

      return CollectionDownloadSummary(
        totalChildren: totalChildren,
        childrenRequested: totalChildDownloads,
        childrenCompleted: totalCompletedChildDownloads
      )
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
        // Check whether we need to update the parent state
        asyncUpdateParentDownloadState(for: download)
      }
    }
  }
  
  /// Asynchronous method to ensure that the parent download object is kept in sync
  /// - Parameter download: The potential child download whose parent we want to update
  private func asyncUpdateParentDownloadState(for download: Download) {
    workerQueue.async { [weak self] in
      guard let self = self else { return }
      
      do {
        var parentDownload: Download?
        try self.db.read { db in
          parentDownload = try download.parentDownload.fetchOne(db)
        }
        if let parentDownload = parentDownload {
          try self.updateCollectionDownloadState(collectionDownload: parentDownload)
        }
      } catch {
        Failure
          .saveToPersistentStore(from: String(describing: type(of: self)), reason: "Unable to update parent.")
          .log()
      }
    }
  }
  
  /// Asynchronous method to ensure that this parent download is kept in sync with its kids
  /// - Parameter parentDownload: The parent object to update
  private func asyncUpdateDownloadState(forParentDownload parentDownload: Download) {
    workerQueue.async { [weak self] in
      guard let self = self else { return }
      
      do {
        try self.updateCollectionDownloadState(collectionDownload: parentDownload)
      } catch {
        Failure
          .saveToPersistentStore(from: String(describing: type(of: self)), reason: "Unable to update parent.")
          .log()
      }
    }
  }
  
  /// Update the collection download to match the current status of its children
  /// - Parameter collectionDownload: A `Download` that is associated with a collection `Content`
  private func updateCollectionDownloadState(collectionDownload: Download) throws {
    let downloadSummary = try collectionDownloadSummary(forContentId: collectionDownload.contentId)
    var download = collectionDownload
    
    _ = try db.write { db in
      if downloadSummary.childrenRequested == 0 {
        try download.delete(db)
      } else {
        try download.updateChanges(db) {
          $0.state = downloadSummary.state
          $0.progress = downloadSummary.progress
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
    asyncUpdateParentDownloadState(for: download)
  }
  
  /// Delete a download
  /// - Parameter id: The UUID of the download to delete
  func deleteDownload(withId id: UUID) throws -> Bool {
    try db.write { db in
      if let download = try Download.fetchOne(db, key: id) {
        let parentDownload = try download.parentDownload.fetchOne(db)
        let response = try download.delete(db)
        if let parentDownload = parentDownload {
          asyncUpdateDownloadState(forParentDownload: parentDownload)
        }
        return response
      }
      return false
    }
  }
  
  /// Delete the downloads without selected IDs.
  /// - Parameter ids: Array of UUIDs for the downloads to delete
  func deleteDownloads(withIds ids: [UUID]) -> Future<Void, Error> {
    Future { promise in
      self.workerQueue.async { [weak self] in
        guard let self = self else { return }
        
        do {
          try self.db.write { db in
            let downloads = try ids.compactMap { try Download.fetchOne(db, key: $0) }
            let parentDownloads = try Set(downloads.compactMap { try $0.parentDownload.fetchOne(db) })
            // Only update parents that we're not gonna delete
            let parentsThatNeedUpdating = parentDownloads.subtracting(downloads)
            
            // Delete all the downloads requested
            try Download.deleteAll(db, keys: ids)
            
            // And update any parents that need doing
            parentsThatNeedUpdating.forEach {
              self.asyncUpdateDownloadState(forParentDownload: $0)
            }
            
            promise(.success(()))
          }
        } catch {
          promise(.failure(error))
        }
      }
    }
  }
  
  /// Delete all the downloads in the database
  func deleteDownloads() throws {
    _ = try db.write { db in
      try Download.deleteAll(db)
    }
  }
  
  /// Save the entire graph of models to supprt this ContentDeailsModel
  /// - Parameter contentPersistableState: The model to persist—from the DataCache.
  func persistContentGraph(for contentPersistableState: ContentPersistableState, contentLookup: ContentLookup? = nil) -> Future<Void, Error> {
    Future { promise in
      self.workerQueue.async { [weak self] in
        guard let self = self else { return }
        do {
          try self.db.write { db in
            try self.persistContentItem(for: contentPersistableState, inDatabase: db, withChildren: true, withParent: true, contentLookup: contentLookup)
          }
          promise(.success(()))
        } catch {
          promise(.failure(error))
        }
      }
    }
  }
  
  func createDownloads(for content: Content) -> Future<Void, Error> {
    Future { promise in
      self.workerQueue.async { [weak self] in
        guard let self = self else { return }
        do {
          try self.db.write { db in
            // Create it for this content item
            try self.createDownload(for: content, inDatabase: db)
            
            // Also need to create one for the parent
            if let parentContent = try content.parentContent.fetchOne(db) {
              try self.createDownload(for: parentContent, inDatabase: db)
            }
            
            // And now for any children that might exist
            let childContent = try content.childContents.order(Content.Columns.ordinal.asc).fetchAll(db)
            try childContent.forEach { contentItem in
              try self.createDownload(for: contentItem, inDatabase: db)
            }
            promise(.success(()))
          }
        } catch {
          promise(.failure(error))
        }
      }
    }
  }
  
  private func createDownload(for content: Content, inDatabase db: Database) throws {
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
