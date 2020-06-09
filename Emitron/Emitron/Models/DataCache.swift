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

enum DataCacheError: Error {
  case cacheMiss
  
  var localizedDescription: String {
    switch self {
    case .cacheMiss:
      return "DataCacheError::CacheMiss"
    }
  }
}

final class DataCache: ObservableObject {
  enum CacheChange {
    case updated
  }
  
  enum CacheInvalidation {
    case progressions
    case bookmarks
  }
  
  private var contents: [Int: Content] = [:]
  private var bookmarks: [Int: Bookmark] = [:]
  private var progressions: [Int: Progression] = [:]
  private var contentIndexedGroups: [Int: [Group]] = [:]
  private var groupIndexedGroups: [Int: Group] = [:]
  private var contentDomains: [Int: [ContentDomain]] = [:]
  private var contentCategories: [Int: [ContentCategory]] = [:]
  
  private let objectDidChange = CurrentValueSubject<CacheChange, Never>(.updated)
  
  let cacheWasInvalidated = PassthroughSubject<CacheInvalidation, Never>()
}

extension DataCache {
  func update(from cacheUpdate: DataCacheUpdate) {
    cacheUpdate.bookmarks.forEach { self.bookmarks[$0.contentId] = $0 }
    // Have to do a special update for content—since some API endpoints won't include group info
    cacheUpdate.contents.forEach { self.contents[$0.id] = self.contents[$0.id]?.update(from: $0) ?? $0 }
    cacheUpdate.progressions.forEach { self.progressions[$0.contentId] = $0 }
    cacheUpdate.groups.forEach { self.groupIndexedGroups[$0.id] = $0 }

    // swiftlint:disable generic_type_name
    func mergeWithCacheUpdate<contentId: Emitron.contentId>(
      _ dictionary: inout [ Int: [contentId] ],
      _ getContentId: (DataCacheUpdate) -> [contentId]
    ) {
      dictionary.merge(
        .init(grouping: getContentId(cacheUpdate), by: \.contentId),
        uniquingKeysWith: { $1 }
      )
    }

    mergeWithCacheUpdate(&contentCategories, \.contentCategories)
    mergeWithCacheUpdate(&contentDomains, \.contentDomains)
    mergeWithCacheUpdate(&contentIndexedGroups, \.groups)

    cacheUpdate.bookmarkDeletionContentIds.forEach { self.bookmarks.removeValue(forKey: $0) }
    cacheUpdate.progressionDeletionContentIds.forEach { self.progressions.removeValue(forKey: $0) }
    
    // Send cach invalidations
    if !cacheUpdate.bookmarks.isEmpty || !cacheUpdate.bookmarkDeletionContentIds.isEmpty {
      cacheWasInvalidated.send(.bookmarks)
    }
    
    if !cacheUpdate.progressions.isEmpty || !cacheUpdate.progressionDeletionContentIds.isEmpty {
      cacheWasInvalidated.send(.progressions)
    }
    
    objectDidChange.send(.updated)
  }
}

/// A type with a `contentId` property.
private protocol contentId {
  var contentId: Int { get }
}

extension ContentCategory: contentId { }
extension ContentDomain: contentId { }
extension Group: contentId { }

extension DataCache {
  func contentSummaryState(for contentIds: [Int]) -> AnyPublisher<[CachedContentSummaryState], Error> {
    self.objectDidChange
      .tryMap { _ in
        try contentIds.map { contentId in
          try self.cachedContentSummaryState(for: contentId)
        }
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func contentSummaryState(for contentId: Int) -> AnyPublisher<CachedContentSummaryState, Error> {
    self.objectDidChange
      .tryMap { _ in
        try self.cachedContentSummaryState(for: contentId)
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func childContentsState(for contentId: Int) -> AnyPublisher<CachedChildContentsState, Error> {
    self.objectDidChange.tryMap { _ in
      try self.cachedChildContentsState(for: contentId)
    }
    .removeDuplicates()
    .eraseToAnyPublisher()
  }
  
  func contentDynamicState(for contentId: Int) -> AnyPublisher<CachedDynamicContentState, Error> {
    self.objectDidChange.tryMap { _ in
      self.cachedDynamicContentState(for: contentId)
    }
    .removeDuplicates()
    .eraseToAnyPublisher()
  }
  
  func content(with id: Int) -> Content? {
    contents[id]
  }
  
  func progression(for contentId: Int) -> Progression? {
    progressions[contentId]
  }
  
  func bookmark(for contentId: Int) -> Bookmark? {
    bookmarks[contentId]
  }
  
  func parentContent(for contentId: Int) -> Content? {
    guard let content = content(with: contentId) else { return nil }
    
    return try? parentContent(for: content)
  }
  
  func childProgress(for contentId: Int) -> (total: Int, completed: Int)? {
    guard let content = content(with: contentId) else { return nil }
    
    guard let childContents = try? childContents(for: content) else { return nil }
    
    let completedCount = childContents
      .compactMap { self.progression(for: $0.id) }
      .filter(\.finished)
      .count
    return (total: childContents.count, completed: completedCount )
  }
}

extension DataCache {
  private func cachedContentSummaryState(for contentId: Int) throws -> CachedContentSummaryState {
    guard let content = self.contents[contentId],
      let contentDomains = self.contentDomains[contentId]
      else {
        throw DataCacheError.cacheMiss
    }
    
    let contentCategories = self.contentCategories[contentId] ?? []
    
    return try CachedContentSummaryState(
      content: content,
      contentDomains: contentDomains,
      contentCategories: contentCategories,
      parentContent: parentContent(for: content)
    )
  }
  
  private func cachedChildContentsState(for contentId: Int) throws -> CachedChildContentsState {
    guard let content = self.contents[contentId] else {
      throw DataCacheError.cacheMiss
    }
    
    if content.contentType != .collection {
      return CachedChildContentsState(contents: [], groups: [])
    }
    
    let groups = self.contentIndexedGroups[contentId] ?? []
    let groupIds = groups.map(\.id)
    let childContents = self.contents.values.filter { content in
      guard let groupId = content.groupId else { return false }
      return groupIds.contains(groupId)
    }
    
    if childContents.isEmpty {
      throw DataCacheError.cacheMiss
    }
    
    return CachedChildContentsState(
      contents: childContents,
      groups: groups
    )
  }
  
  func cachedContentPersistableState(for contentId: Int) throws -> ContentPersistableState {
    guard let content = self.contents[contentId] else {
        throw DataCacheError.cacheMiss
      }
    
      let contentDomains = self.contentDomains[contentId] ?? []
      let contentCategories = self.contentCategories[contentId] ?? []
      
      if content.contentType != .episode {
        if contentDomains.isEmpty {
          throw DataCacheError.cacheMiss
        }
      }
      
      let bookmark = self.bookmarks[contentId]
      let progression = self.progressions[contentId]
      let groups = self.contentIndexedGroups[contentId] ?? []
      let groupIds = groups.map(\.id)
      let childContents = self.contents.values.filter { content in
        guard let groupId = content.groupId else { return false }
        return groupIds.contains(groupId)
      }
      
      return try ContentPersistableState(
        content: content,
        contentDomains: contentDomains,
        contentCategories: contentCategories,
        bookmark: bookmark,
        parentContent: parentContent(for: content),
        progression: progression,
        groups: groups,
        childContents: childContents
      )
  }
  
  func videoPlaylist(for contentId: Int) throws -> [CachedVideoPlaybackState] {
    guard let content = self.contents[contentId] else {
      throw DataCacheError.cacheMiss
    }
    
    // If it's a screencast then we can just return this single one
    if content.contentType == .screencast {
      return [videoPlaybackState(for: content)]
    }
    
    // If it's an episode, find this and all the following episodes
    if content.contentType == .episode {
      let siblings = try siblingContents(for: content)
      // Only want ones later than this one
      let playlist = siblings.drop { $0 != content }
      return playlist.map { videoPlaybackState(for: $0) }
    }
    
    // If it's a collection then find where we got up to, and send from there
    if content.contentType == .collection {
      let children = try childContents(for: content)
      let nextEpisode = try nextToPlay(for: children)
      let playlist = children.drop { $0 != nextEpisode }
      return playlist.map { videoPlaybackState(for: $0) }
    }
    
    // Out of options
    return []
  }
  
  private func videoPlaybackState(for content: Content) -> CachedVideoPlaybackState {
    CachedVideoPlaybackState(
      content: content,
      progression: progressions[content.id]
    )
  }
  
  private func cachedDynamicContentState(for contentId: Int) -> CachedDynamicContentState {
    CachedDynamicContentState(
      progression: self.progressions[contentId],
      bookmark: self.bookmarks[contentId]
    )
  }
  
  private func parentContent(for content: Content) throws -> Content? {
    guard let groupId = content.groupId else { return nil }
    guard let group = self.groupIndexedGroups[groupId]
      else { throw DataCacheError.cacheMiss }
    
    return self.contents[group.contentId]
  }
  
  private func childContents(for content: Content) throws -> [Content] {
    guard let groups = contentIndexedGroups[content.id] else {
      throw DataCacheError.cacheMiss
    }
    
    let groupIds = groups.map(\.id)
    return contents.values.filter {
      guard let groupId = $0.groupId else { return false }
      return groupIds.contains(groupId)
    }
    .sorted {
      guard let lhsOrdinal = $0.ordinal, let rhsOrdinal = $1.ordinal else { return true }
      return lhsOrdinal < rhsOrdinal
    }
  }
  
  private func siblingContents(for content: Content) throws -> [Content] {
    guard let parentContent = try parentContent(for: content) else {
      return []
    }
    return try childContents(for: parentContent)
  }
  
  private func nextToPlay(for contentList: [Content]) throws -> Content {
    guard !contentList.isEmpty else { throw DataCacheError.cacheMiss }
    
    // We'll assume that the contents is already ordered. It is if it comes from child/sibling contents
    let orderedProgressions = contentList.map { progressions[$0.id] }
    
    // Find the first index where there's a missing or incomplete progression
    guard let incompleteOrNotStartedIndex = orderedProgressions.firstIndex(where: { progression in
      guard let progression = progression else { return true }
      
      return !progression.finished
    }) else {
      // If we didn't find one, start at the beginning
      return contentList[0]
    }
    
    // Otherwise, we've found the one we need
    return contentList[incompleteOrNotStartedIndex]
  }
}
