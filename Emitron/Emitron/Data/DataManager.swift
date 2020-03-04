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

import UIKit
import Combine

final class DataManager: ObservableObject {

  // MARK: - Properties
  // Initialiser Arguments
  let persistenceStore: PersistenceStore
  let downloadService: DownloadService
  let sessionController: SessionController
  private (set) var sessionControllerSubscription: AnyCancellable!

  // Persisted information
  private (set) var domainRepository: DomainRepository!
  private (set) var categoryRepository: CategoryRepository!
  var filters = Filters()
  
  // Cached data
  var dataCache = DataCache()
  private (set) var repository: Repository!
  
  // Content repositories
  private (set) var bookmarkRepository: BookmarkRepository!
  private (set) var completedRepository: CompletedRepository!
  private (set) var inProgressRepository: InProgressRepository!
  private (set) var libraryRepository: LibraryRepository!
  private (set) var downloadRepository: DownloadRepository!
  
  // Services
  private (set) var syncEngine: SyncEngine!

  private var domainsSubscriber: AnyCancellable?
  private var categoriesSubsciber: AnyCancellable?

  // MARK: - Initializers
  init(sessionController: SessionController,
       persistenceStore: PersistenceStore,
       downloadService: DownloadService) {
    
    self.downloadService = downloadService
    self.persistenceStore = persistenceStore
    self.sessionController = sessionController
    
    sessionControllerSubscription = sessionController.objectWillChange.sink { [weak self] in
      guard let self = self else { return }
      self.rebuildRepositories()
    }
    
    rebuildRepositories()
  }
  
  private func rebuildRepositories() {
    // We're all changing—let's announce it
    objectWillChange.send()
    
    // Empty the caches
    dataCache = DataCache()
    filters = Filters()
    
    repository = Repository(persistenceStore: persistenceStore, dataCache: dataCache)
    
    let contentsService = ContentsService(client: sessionController.client)
    let bookmarksService = BookmarksService(client: sessionController.client)
    let progressionsService = ProgressionsService(client: sessionController.client)
    let libraryService = ContentsService(client: sessionController.client)
    let domainsService = DomainsService(client: sessionController.client)
    let categoriesService = CategoriesService(client: sessionController.client)
    let watchStatsService = WatchStatsService(client: sessionController.client)
    
    syncEngine = SyncEngine(
      persistenceStore: persistenceStore,
      repository: repository,
      bookmarksService: bookmarksService,
      progressionsService: progressionsService,
      watchStatsService: watchStatsService
    )
    
    bookmarkRepository = BookmarkRepository(repository: repository, contentsService: contentsService, downloadAction: downloadService, syncAction: syncEngine, serviceAdapter: bookmarksService)
  
    completedRepository = CompletedRepository(repository: repository, contentsService: contentsService, downloadAction: downloadService, syncAction: syncEngine, serviceAdapter: progressionsService)
    inProgressRepository = InProgressRepository(repository: repository, contentsService: contentsService, downloadAction: downloadService, syncAction: syncEngine, serviceAdapter: progressionsService)
    
    libraryRepository = LibraryRepository(repository: repository, contentsService: contentsService, downloadAction: downloadService, syncAction: syncEngine, serviceAdapter: libraryService)
    
    downloadRepository = DownloadRepository(repository: repository, contentsService: contentsService, downloadService: downloadService, syncAction: syncEngine)
    
    domainRepository = DomainRepository(repository: repository, service: domainsService)
    domainsSubscriber = domainRepository.$domains.sink { domains in
      self.filters.updatePlatformFilters(for: domains)
    }
    
    categoryRepository = CategoryRepository(repository: repository, service: categoriesService)
    categoriesSubsciber = categoryRepository.$categories.sink { categories in
      self.filters.updateCategoryFilters(for: categories)
    }
  }
}
