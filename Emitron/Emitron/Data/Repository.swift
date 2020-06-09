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

class Repository {
  private let persistenceStore: PersistenceStore
  private let dataCache: DataCache
  
  init(persistenceStore: PersistenceStore, dataCache: DataCache) {
    self.persistenceStore = persistenceStore
    self.dataCache = dataCache
  }
}

extension Repository {
  func apply(update: DataCacheUpdate) {
    dataCache.update(from: update)
  }
}

extension Repository {
  func contentSummaryState(for contentIds: [Int]) -> AnyPublisher<[ContentSummaryState], Error> {
    dataCache
      .contentSummaryState(for: contentIds)
      .map { cachedContentSummaryStates in
        cachedContentSummaryStates.map { cached in
          self.contentSummaryState(cached: cached)
        }
      }
      .eraseToAnyPublisher()
  }
  
  func contentSummaryState(for contentId: Int) -> AnyPublisher<ContentSummaryState, Error> {
    dataCache
      .contentSummaryState(for: contentId)
      .map { cachedContentSummaryState in
        self.contentSummaryState(cached: cachedContentSummaryState)
      }
      .eraseToAnyPublisher()
  }
  
  func childContentsState(for contentId: Int) -> AnyPublisher<ChildContentsState, Error> {
    dataCache
      .childContentsState(for: contentId)
  }
  
  func contentDynamicState(for contentId: Int) -> AnyPublisher<DynamicContentState, Error> {
    let fromCache = dataCache.contentDynamicState(for: contentId)
    let download = persistenceStore.download(for: contentId)
    
    return fromCache
      .combineLatest(download)
      .map { cachedState, download in
        DynamicContentState(download: download,
                            progression: cachedState.progression,
                            bookmark: cachedState.bookmark)
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func contentPersistableState(for contentId: Int) throws -> ContentPersistableState? {
    try dataCache.cachedContentPersistableState(for: contentId)
  }
  
  /// Return an array of states that provide the playlist of what should be played for this item of content
  /// - Parameter contentId: The id of the `Content` the user has requested to be played back
  func playlist(for contentId: Int) throws -> [VideoPlaybackState] {
    let fromCache = try dataCache.videoPlaylist(for: contentId)
    return try fromCache.map { cachedState in
      let download = try persistenceStore.download(forContentId: cachedState.content.id)
      return VideoPlaybackState(
        content: cachedState.content,
        progression: cachedState.progression,
        download: download)
    }
  }
  
  /// Find the specified item of content in the cache
  /// - Parameter id: The `id` of the content to return
  func content(for id: Int) -> Content? {
    dataCache.content(with: id)
  }
  
  /// Attempt to find a progression from the cache for a given item of content
  /// - Parameter contentId: The `id` of the content item
  func progression(for contentId: Int) -> Progression? {
    dataCache.progression(for: contentId)
  }
  
  /// Attempt to locate a bookmark from the cache for a given item of content
  /// - Parameter contentId: The `id` of the content item
  func bookmark(for contentId: Int) -> Bookmark? {
    dataCache.bookmark(for: contentId)
  }
  
  func parentContent(for contentId: Int) -> Content? {
    dataCache.parentContent(for: contentId)
  }
  
  func childProgress(for contentId: Int) -> (total: Int, completed: Int)? {
    dataCache.childProgress(for: contentId)
  }
  
  func domainList() throws -> [Domain] {
    try persistenceStore.domainList()
  }
  
  func syncDomainList(_ domains: [Domain]) throws {
    try persistenceStore.sync(domains: domains)
  }
  
  func categoryList() throws -> [Category] {
    try persistenceStore.categoryList()
  }
  
  func syncCategoryList(_ categories: [Category]) throws {
    try persistenceStore.sync(categories: categories)
  }
  
  func loadDownloadedChildContentsIntoCache(for contentId: Int) throws {
    guard let content = try persistenceStore.downloadedContent(with: contentId),
      let childContents = try persistenceStore.childContentsForDownloadedContent(with: contentId) else {
      throw PersistenceStoreError.notFound
    }
    let cacheUpdate = DataCacheUpdate(contents: childContents.contents + [content], groups: childContents.groups)
    apply(update: cacheUpdate)
  }
  
  private func contentSummaryState(cached: CachedContentSummaryState) -> ContentSummaryState {
    ContentSummaryState(
      content: cached.content,
      domains: self.domains(from: cached.contentDomains),
      categories: self.categories(from: cached.contentCategories),
      parentContent: cached.parentContent
    )
  }
  
  private func domains(from contentDomains: [ContentDomain]) -> [Domain] {
    do {
      return try persistenceStore.domains( with: contentDomains.map(\.domainId) )
    } catch {
      Failure
        .loadFromPersistentStore(from: String(describing: type(of: self)), reason: "There was a problem getting domains: \(error)")
        .log()
      return []
    }
  }
  
  private func categories(from contentCategories: [ContentCategory]) -> [Category] {
    do {
      return try persistenceStore.categories( with: contentCategories.map(\.categoryId) )
    } catch {
      Failure
        .loadFromPersistentStore(from: String(describing: type(of: self)), reason: "There was a problem getting categories: \(error)")
        .log()
      return []
    }
  }
}

// MARK: - Cache invalidations
extension Repository {
  var cachedBookmarksInvalidated: AnyPublisher<Void, Never> {
    dataCache
      .cacheWasInvalidated
      .filter { $0 == .bookmarks }
      .map { _ in }
      .eraseToAnyPublisher()
  }
  
  var cachedProgressionsInvalidated: AnyPublisher<Void, Never> {
    dataCache
      .cacheWasInvalidated
      .filter { $0 == .progressions }
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
