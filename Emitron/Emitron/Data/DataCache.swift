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
  private var contents: [Int : Content] = [Int : Content]()
  private var bookmarks: [Int : Bookmark] = [Int : Bookmark]()
  private var progressions: [Int : Progression] = [Int : Progression]()
  private var contentIndexedGroups: [Int : [Group]] = [Int : [Group]]()
  private var groupIndexedGroups: [Int : Group] = [Int : Group]()
  private var contentDomains: [Int : [ContentDomain]] = [Int : [ContentDomain]]()
  private var contentCategories: [Int : [ContentCategory]] = [Int : [ContentCategory]]()
  
  private let objectDidChange: CurrentValueSubject<CacheChange, Never> = CurrentValueSubject<CacheChange, Never>(.updated)
}


extension DataCache {
  func update(from cacheUpdate: DataCacheUpdate) {
    cacheUpdate.bookmarks.forEach { self.bookmarks[$0.contentId] = $0 }
    cacheUpdate.contents.forEach { self.contents[$0.id] = $0 }
    cacheUpdate.progressions.forEach { self.progressions[$0.id] = $0 }
    cacheUpdate.groups.forEach { self.groupIndexedGroups[$0.id] = $0 }
    
    let newContentCategories = Dictionary(grouping: cacheUpdate.contentCategories) { $0.contentId }
    let newContentDomains = Dictionary(grouping: cacheUpdate.contentDomains) { $0.contentId }
    let newContentIndexedGroups = Dictionary(grouping: cacheUpdate.groups) { $0.contentId }
    
    self.contentCategories.merge(newContentCategories)
    self.contentDomains.merge(newContentDomains)
    self.contentIndexedGroups.merge(newContentIndexedGroups)
    
    objectDidChange.send(.updated)
  }
}

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
  
  func contentDetailState(for contentId: Int) -> AnyPublisher<CachedContentDetailState, Error> {
    self.objectDidChange.tryMap { _ in
      try self.cachedContentDetailState(for: contentId)
    }
    .removeDuplicates()
    .eraseToAnyPublisher()
  }
}


extension DataCache {
  private func cachedContentSummaryState(for contentId: Int) throws -> CachedContentSummaryState {
    guard let content = self.contents[contentId],
      let contentDomains = self.contentDomains[contentId]
      else {
        throw DataCacheError.cacheMiss
    }
    
    let bookmark = self.bookmarks[contentId]
    let progression = self.progressions[contentId]
    
    return try CachedContentSummaryState(
      content: content,
      contentDomains: contentDomains,
      bookmark: bookmark,
      parentContent: parentContent(for: content),
      progression: progression
    )
  }
  
  private func cachedContentDetailState(for contentId: Int) throws -> CachedContentDetailState {
    guard let content = self.contents[contentId],
      let contentDomains = self.contentDomains[contentId],
      let contentCategories = self.contentCategories[contentId]
      else {
        throw DataCacheError.cacheMiss
    }
    
    let bookmark = self.bookmarks[contentId]
    let progression = self.progressions[contentId]
    let groups = self.contentIndexedGroups[contentId] ?? []
    let groupIds = groups.map { $0.id }
    let childContents = self.contents.values.filter { content in
      if content.groupId == nil { return false }
      return groupIds.contains(content.groupId!)
    }
    
    return try CachedContentDetailState(
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
  
  func cachedContentPersistableState(for contentId: Int) throws -> ContentPersistableState {
    try cachedContentDetailState(for: contentId)
  }
  
  private func parentContent(for content: Content) throws -> Content? {
    guard let groupId = content.groupId else { return nil }
    guard let group = self.groupIndexedGroups[groupId]
      else { throw DataCacheError.cacheMiss }
    
    return self.contents[group.contentId]
  }
}
