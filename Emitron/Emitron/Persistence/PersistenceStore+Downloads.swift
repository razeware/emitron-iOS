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
import struct Foundation.UUID
import GRDB

// MARK: - Data reading methods for display
extension PersistenceStore {
  /// List of all downloads
  func downloadList() -> DatabasePublishers.Value<[ContentSummaryState]> {
    ValueObservation.tracking { db -> [ContentSummaryState] in
      let contentTypes = [ContentType.collection, .screencast].map(\.rawValue)
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
  func download(for contentID: Int) -> DatabasePublishers.Value<Download?> {
    ValueObservation.tracking { db -> Download? in
      let request = Download
        .filter(Download.Columns.contentID == contentID)
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
        .filter(Group.Columns.contentID == id)
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
  
  /// Returns a publisher representing the download queue over time
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
  func download(withID id: UUID) throws -> Download? {
    try db.read { db in
      try Download.fetchOne(db, key: id)
    }
  }
  
  /// Return a single `Download` from its content id
  /// - Parameter contentID: The ID of the item of content this download refers to
  func download(forContentID contentID: Int) throws -> Download? {
    try db.read { db in
      try Download
        .filter(Download.Columns.contentID == contentID)
        .fetchOne(db)
    }
  }
  
  /// Used to determine the state of the `Download` for a collection
  struct CollectionDownloadSummary: Equatable {
    let totalChildren: Int
    let childrenRequested: Int
    let childrenCompleted: Int
    
    var state: Download.State {
      if childrenRequested == childrenCompleted, childrenCompleted == totalChildren {
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
  /// - Parameter contentID: ID representing an item of `Content` with `ContentType` of `.collection`
  func collectionDownloadSummary(forContentID contentID: Int) async throws -> CollectionDownloadSummary {
    try await db.read { db in
      guard
        let content = try Content.fetchOne(db, key: contentID),
        content.contentType == .collection
      else {
        throw PersistenceStoreError.argumentError
      }

      return .init(
        totalChildren: try content.childContents.fetchCount(db),
        childrenRequested: try content.childDownloads.fetchCount(db),
        childrenCompleted:
          try content.childDownloads
          .filter(Download.Columns.state == Download.State.complete.rawValue)
          .fetchCount(db)
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
  func transitionDownload(withID id: UUID, to state: Download.State) async throws {
    guard let download = try await db.read({ db in
      try Download.fetchOne(db, key: id)
    }) else {
      return
    }

    try await db.write { [download] db in
      var download = download
      try download.updateChanges(db) {
        $0.state = state
      }
    }

    // Check whether we need to update the parent state
    try await asyncUpdateParentDownloadState(for: download)
  }
  
  /// Asynchronous method to ensure that the parent download object is kept in sync
  /// - Parameter download: The potential child download whose parent we want to update
  private func asyncUpdateParentDownloadState(for download: Download) async throws {
    do {
      if let parentDownload = try await db.read({ db in
        try download.parentDownload.fetchOne(db)
      }) {
        try await updateCollectionDownloadState(collectionDownload: parentDownload)
      }
    } catch {
      Failure
        .saveToPersistentStore(from: Self.self, reason: "Unable to update parent.")
        .log()
    }
  }
  
  /// Asynchronous method to ensure that this parent download is kept in sync with its kids
  /// - Parameter parentDownload: The parent object to update
  private func asyncUpdateDownloadState(forParentDownload parentDownload: Download) {
    Task {
      do {
        try await updateCollectionDownloadState(collectionDownload: parentDownload)
      } catch {
        Failure
          .saveToPersistentStore(from: Self.self, reason: "Unable to update parent.")
          .log()
      }
    }
  }
  
  /// Update the collection download to match the current status of its children
  /// - Parameter collectionDownload: A `Download` that is associated with a collection `Content`
  private func updateCollectionDownloadState(collectionDownload: Download) async throws {
    let downloadSummary = try await collectionDownloadSummary(forContentID: collectionDownload.contentID)

    try await db.write { db in
      var download = collectionDownload
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
  func updateDownload(withID id: UUID, withProgress progress: Double) throws {
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
  func update(download: Download) async throws {
    try await db.write { db in
      try download.update(db)
    }
    Task { try await asyncUpdateParentDownloadState(for: download) }
  }
  
  /// Delete a download
  /// - Parameter id: The UUID of the download to delete
  func deleteDownload(withID id: UUID) throws -> Bool {
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
  func deleteDownloads(withIDs ids: [UUID]) async throws {
    try await db.write { db in
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
    }
  }

  /// Save the entire graph of models to support this ContentDeailsModel
  /// - Parameter contentPersistableState: The model to persist—from the DataCache.
  func persistContentGraph(
    for contentPersistableState: ContentPersistableState,
    contentLookup: ContentLookup? = nil
  ) async throws {
    try await db.write { db in
      try Self.persistContentItem(
        for: contentPersistableState,
        inDatabase: db,
        withChildren: true,
        withParent: true,
        contentLookup: contentLookup
      )
    }
  }
  
  func createDownloads(for content: Content) async throws {
    try await db.write { db in
      func createDownload(for content: Content) throws {
        // Check whether this already exists
        if try content.download.fetchCount(db) > 0 {
          return
        }
        // Create and save the Download
        var download = Download(content: content)
        try download.insert(db)
      }

      // Create it for this content item
      try createDownload(for: content)

      // Also need to create one for the parent
      if let parentContent = try content.parentContent.fetchOne(db) {
        try createDownload(for: parentContent)
      }

      // And now for any children that might exist
      let childContent = try content.childContents.order(Content.Columns.ordinal.asc).fetchAll(db)
      try childContent.forEach(createDownload)
    }
  }
}

// MARK: - private
private extension PersistenceStore {
  /// Save a content item, optionally including its parent and children
  /// - Parameters:
  ///   - contentDetailState: The ContentDetailState to persist
  ///   - db: A `Database` object to save it
  static func persistContentItem(
    for contentPersistableState: ContentPersistableState,
    inDatabase db: Database,
    withChildren: Bool = false,
    withParent: Bool = false,
    contentLookup: ContentLookup? = nil
  ) throws {
    // 1. Need to do parent first—we need foreign key
    //    constraints on the groupID for child content
    if
      withParent,
      let parentContent = contentPersistableState.parentContent,
      let contentLookup = contentLookup
    {
      let parentPersistable = try contentLookup(parentContent.id)
      try persistContentItem(
        for: parentPersistable,
        inDatabase: db,
        withChildren: true,
        contentLookup: contentLookup
      )
    }
    
    // 2. Generate and save this content item
    try contentPersistableState.content.save(db)
    
    // 3. Groups
    try contentPersistableState.groups.forEach { try $0.save(db) }
    
    // 4. Children
    if withChildren, let contentLookup = contentLookup {
      try contentPersistableState.childContents.forEach { content in
        let childPersistable = try contentLookup(content.id)
        try persistContentItem(for: childPersistable, inDatabase: db)
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
