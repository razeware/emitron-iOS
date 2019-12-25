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

class Repository {
  private let persistenceStore: PersistenceStore
  private let dataCache: DataCache
  
  init(persistenceStore: PersistenceStore, dataCache: DataCache) {
    self.persistenceStore = persistenceStore
    self.dataCache = dataCache
  }
  
}

enum RepositoryError: Error {
  case never
}

extension Repository {
  func apply(update: DataCacheUpdate) {
    dataCache.update(from: update)
  }
}


extension Repository {
  func contentSummaryState(for contentIds: [Int]) -> AnyPublisher<[ContentSummaryState], Error> {
    let fromCache = dataCache.contentSummaryState(for: contentIds)
    let downloads = persistenceStore.downloads(for: contentIds)
    
    return fromCache
      .mapError { _ in RepositoryError.never }
      .combineLatest(downloads)
      .map { (cachedContentSummaryStates, downloads) in
        cachedContentSummaryStates.map { cached in
          self.contentSummaryState(cached: cached, downloads: downloads)
        }
    }.eraseToAnyPublisher()
  }
  
  func contentDetailState(for contentId: Int) -> AnyPublisher<ContentDetailState, Error> {
    let fromCache = dataCache.contentDetailState(for: contentId)
    let download = persistenceStore.download(for: contentId)
    
    return fromCache
      .mapError { _ in RepositoryError.never }
      .combineLatest(download)
      .map { (cachedContentDetailState, download) in
        self.contentDetailState(cached: cachedContentDetailState, download: download)
    }.eraseToAnyPublisher()
  }
  
  private func contentSummaryState(cached: CachedContentSummaryState, downloads: [Download]) -> ContentSummaryState {
    ContentSummaryState(
      content: cached.content,
      domains: self.domains(from: cached.contentDomains),
      download: downloads.first { $0.contentId == cached.content.id },
      bookmark: cached.bookmark,
      parentContent: cached.parentContent,
      progression: cached.progression
    )
  }
  
  private func contentDetailState(cached: CachedContentDetailState,
                                  download: Download?) -> ContentDetailState {
    ContentDetailState(
      content: cached.content,
      domains: self.domains(from: cached.contentDomains),
      categories: self.categories(from: cached.contentCategories),
      download: download,
      bookmark: cached.bookmark,
      parentContent: cached.parentContent,
      progression: cached.progression,
      groups: cached.groups,
      childContents: cached.childContents
    )
  }
  
  private func domains(from contentDomains: [ContentDomain]) -> [Domain] {
    do {
      return try persistenceStore.domains(with: contentDomains.map { $0.domainId })
    } catch {
      // TODO log
      print("There was a problem getting domains: \(error)")
      return [Domain]()
    }
  }
  
  private func categories(from contentCategories: [ContentCategory]) -> [Category] {
    do {
      return try persistenceStore.categories(with: contentCategories.map { $0.categoryId })
    } catch {
      // TODO log
      print("There was a problem getting categories: \(error)")
      return [Category]()
    }
  }
}
