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
  /// The data required to populate the download list
  struct DownloadListItem: Decodable, FetchableRecord {
    let content: Content
    let domains: [Domain]
    let download: Download
  }
  
  /// List of all downloads
  func downloadList() -> DatabasePublishers.Value<[DownloadListItem]> {
    ValueObservation.tracking { db -> [DownloadListItem] in
      let request = Content
        .including(required: Content.download)
        .including(all: Content.domains)
        
      return try DownloadListItem.fetchAll(db, request)
    }.publisher(in: db)
  }
}

extension PersistenceStore {
  /// The data required to render a downloaded item of content
  struct DownloadDetailItem: Decodable, FetchableRecord {
    let content: Content
    let domains: [Domain]
    let download: Download
    let childContents: [Content]?
  }
  
  
  /// Request details of a specific download
  /// - Parameter contentId: The id of the item of content to show
  func downloadDetail(contentId: Int) -> DatabasePublishers.Value<DownloadDetailItem?> {
    ValueObservation.tracking { db -> DownloadDetailItem? in
      let request = Content
        .filter(key: contentId)
        .including(required: Content.download)
        .including(all: Content.domains)
        .including(all: Content.childContents)
      return try DownloadDetailItem.fetchOne(db, request)
    }.publisher(in: db)
  }
}

// MARK: - Data reading methods for download queue management
extension PersistenceStore {
  /// Data required for operation of the download queue
  struct DownloadQueueItem: Decodable, FetchableRecord {
    let download: Download
    let content: Content
  }
  /// Returns a publisher of all downloads in a given state
  /// - Parameter state: The `Download.State` to filter the results by
  func downloads(in state: Download.State) -> DatabasePublishers.Value<DownloadQueueItem?> {
    ValueObservation.tracking { db -> DownloadQueueItem? in
      let request = Download
        .including(required: Download.content)
        .filter(state: state)
        .orderByRequestedAt()
      return try DownloadQueueItem.fetchOne(db, request)
    }.publisher(in: db)
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
  /// - Parameter contentDetailsModel: The model to persist. Including children & parents.
  func persistContentGraph(for contentDetailsModel: ContentDetailsModel) throws -> Content {
    try db.write { db in
      try persistContentItem(for: contentDetailsModel, inDatabase: db, withParent: true, withChildren: true)
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
  ///   - contentDetailsModel: The ContentDetailsModel to persist
  ///   - db: A `Database` object to save it
  ///   - groupId: Optionally, assign this new `Content` to a particular `Group`
  ///   - withParent: Should it recurively attempt to persist the parent content?
  ///   - withChildren: Should it recursively attempt to persiste the child contents?
  private func persistContentItem(for contentDetailsModel: ContentDetailsModel, inDatabase db: Database, groupId: Int? = nil, withParent: Bool = false, withChildren: Bool = false) throws -> Content {
    // 1. Generate and save this content item
    var content = Content(contentDetailsModel: contentDetailsModel)
    content.groupId = groupId
    try content.save(db)
    
    // 2. Parent item
    if let parentItem = contentDetailsModel.parentContent, withParent {
      // Parents can't have parents, but we do want all children
      let _ = try persistContentItem(for: parentItem, inDatabase: db, withParent: false, withChildren: true)
      // Skip groups here—let's make parents responsible for creating them
    }
    
    // 3. Children
    if withChildren {
      try contentDetailsModel.groups.forEach { groupModel in
        // 4. Create this group
        var group = Group(groupModel: groupModel)
        group.contentId = content.id
        try group.save(db)
        
        // Now the child contents
        try groupModel.childContents.forEach { childItem in
          // We're the parent, and children can't have children
          let _ = try persistContentItem(for: childItem, inDatabase: db, groupId: group.id, withParent: false, withChildren: false)
        }
      }
    }
    
    // 5. Domains
    try syncDomains(for: contentDetailsModel, with: content, inDatabase: db)
    
    // 6. Categories
    try syncCategories(for: contentDetailsModel, with: content, inDatabase: db)
    
    // 7. Bookmark
    if let bookmarkModel = contentDetailsModel.bookmark {
      var bookmark = Bookmark(bookmarkModel: bookmarkModel)
      bookmark.contentId = content.id
      try bookmark.save(db)
    }
    
    // 8. Progression
    if let progressionModel = contentDetailsModel.progression {
      var progression = Progression(progressionModel: progressionModel)
      progression.contentId = content.id
      try progression.save(db)
    }
    
    // 9. And relax.
    return content
  }
  
  /// Sync domains for a CDM. Ensure the Domain exists, and then check the ContentDomain objects
  /// - Parameters:
  ///   - contentDetailsModel: The CDM whose domains you want to synchronise
  ///   - content: The Content item to sync the domains to
  ///   - db: A `Database` object to save the Domain and ContentDomain
  private func syncDomains(for contentDetailsModel: ContentDetailsModel, with content: Content, inDatabase db: Database) throws {
    // Get existing ContentDomains
    let contentDomains = try content.contentDomains.fetchAll(db)
    // Get some ids
    let cdmDomainIds = Set(contentDetailsModel.domains.map { $0.id })
    let cdIds = Set(contentDomains.map { $0.domainId })
    // Diff them with the domains from the CDM
    let domainIdsToAdd = cdmDomainIds.subtracting(cdIds)
    let domainIdsToRemove = cdIds.subtracting(cdmDomainIds)
    
    // Handle removal
    try contentDomains
      .filter { domainIdsToRemove.contains($0.domainId) }
      .forEach { try $0.delete(db) }
    
    // Handle addition
    let domainModelsToAdd = contentDetailsModel.domains.filter { domainIdsToAdd.contains($0.id) }
    try domainModelsToAdd.forEach { domainModel in
      // Check that the domain exists
      let domain = Domain(domainModel: domainModel)
      if try !domain.exists(db) {
        try domain.insert(db)
      }
      // Create the ContentDomain as appropriate
      var contentDomain = ContentDomain(contentId: content.id, domainId: domain.id)
      try contentDomain.insert(db)
    }
  }
  
  /// Sync categories for a CDM. Ensure the Category exists, and then check the ContentCategory objects
  /// - Parameters:
  ///   - contentDetailsModel: The CDM whose categories you want to synchronise
  ///   - content: The Content item to sync the categories to
  ///   - db: A `Database` object to save the Category and ContentCategory
  private func syncCategories(for contentDetailsModel: ContentDetailsModel, with content: Content, inDatabase db: Database) throws {
    // Get existing ContentCategories
    let contentCategories = try content.contentCategories.fetchAll(db)
    // Get some ids
    let cdmCategoryIds = Set(contentDetailsModel.categories.map { $0.id })
    let ccIds = Set(contentCategories.map { $0.categoryId })
    // Diff them with the categories from the CDM
    let categoryIdsToAdd = cdmCategoryIds.subtracting(ccIds)
    let categoryIdsToRemove = ccIds.subtracting(cdmCategoryIds)
    
    // Handle removal
    try contentCategories
      .filter { categoryIdsToRemove.contains($0.categoryId) }
      .forEach { try $0.delete(db) }
    
    // Handle addition
    let categoryModelsToAdd = contentDetailsModel.categories.filter { categoryIdsToAdd.contains($0.id) }
    try categoryModelsToAdd.forEach { categoryModel in
      // Check that the category exists
      let category = Category(categoryModel: categoryModel)
      if try !category.exists(db) {
        try category.insert(db)
      }
      // Create ContentCategory as appropriate
      var contentCategory = ContentCategory(contentId: content.id, categoryId: category.id)
      try contentCategory.insert(db)
    }
  }
}
