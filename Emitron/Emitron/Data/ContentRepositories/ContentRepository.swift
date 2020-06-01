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

class ContentRepository: ObservableObject, ContentPaginatable {
  let repository: Repository
  let contentsService: ContentsService
  let downloadAction: DownloadAction
  weak var syncAction: SyncAction?
  let serviceAdapter: ContentServiceAdapter!
  
  private (set) var currentPage: Int = 1
  private (set) var totalContentNum: Int = 0
  
  // This should be @Published, but it /sometimes/ crashes the app with EXC_BAD_ACCESS
  // when you try and reference it. Which is handy.
  var contents: [ContentListDisplayable] = [] {
    willSet {
      objectWillChange.send()
    }
  }

  // This should be @Published too, but it crashes the compiler (Version 11.3 (11C29))
  // Let's see if we actually need it to be @Published...
  var state: DataState = .initial
  
  private var contentIds: [Int] = []
  private var contentSubscription: AnyCancellable?
  // Provide a value for this in a subclass to subscribe to invalidation notifcations
  var invalidationPublisher: AnyPublisher<Void, Never>? { nil }
  private var invalidationSubscription: AnyCancellable?
  
  var isEmpty: Bool {
    contents.isEmpty
  }
  
  var nonPaginationParameters = [Parameter]() {
    didSet {
      if state != .initial { reload() }
    }
  }
  
  // Initialiser
  init(repository: Repository,
       contentsService: ContentsService,
       downloadAction: DownloadAction,
       syncAction: SyncAction,
       serviceAdapter: ContentServiceAdapter?) {
    self.repository = repository
    self.contentsService = contentsService
    self.downloadAction = downloadAction
    self.syncAction = syncAction
    self.serviceAdapter = serviceAdapter
    configureInvalidationSubscription()
  }

  func loadMore() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    guard contentIds.isEmpty || contentIds.count <= totalContentNum else {
      return
    }
    
    state = .loadingAdditional
    currentPage += 1
    
    let pageParam = ParameterKey.pageNumber(number: currentPage).param
    let allParams = nonPaginationParameters + [pageParam]
    
    serviceAdapter.findContent(parameters: allParams) { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .failure(let error):
        self.currentPage -= 1
        self.state = .failed
        self.objectWillChange.send()
        Failure
          .fetch(from: String(describing: type(of: self)), reason: error.localizedDescription)
          .log()
      case .success(let (newContentIds, cacheUpdate, totalResultCount)):
        self.contentIds += newContentIds
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalResultCount
        self.state = .hasData
        self.configureContentSubscription()
      }
    }
  }
  
  func reload() {
    if state == .loading || state == .loadingAdditional {
      return
    }
    
    state = .loading
    // `state` can't be @Published, so we have to do this manually
    objectWillChange.send()
    
    // Reset current page to 1
    currentPage = startingPage
    
    serviceAdapter.findContent(parameters: nonPaginationParameters) {  [weak self] result in
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        self.objectWillChange.send()
        Failure
          .fetch(from: String(describing: type(of: self)), reason: error.localizedDescription)
          .log()
      case .success(let (newContentIds, cacheUpdate, totalResultCount)):
        self.contentIds = newContentIds
        self.contentSubscription?.cancel()
        self.repository.apply(update: cacheUpdate)
        self.totalContentNum = totalResultCount
        self.state = .hasData
        self.configureContentSubscription()
      }
    }
  }
  
  private func configureContentSubscription() {
    self.contentSubscription = self.repository
      .contentSummaryState(for: self.contentIds)
      .removeDuplicates()
      .sink(receiveCompletion: { [weak self] error in
        guard let self = self else { return }
        
        Failure
          .repositoryLoad(from: String(describing: type(of: self)), reason: "Unable to receive content summary update: \(error)")
          .log()
    }, receiveValue: { [weak self] contentSummaryStates in
      guard let self = self else { return }
      
      self.contents = contentSummaryStates
    })
  }
  
  private func configureInvalidationSubscription() {
    if let invalidationPublisher = invalidationPublisher {
      self.invalidationSubscription = invalidationPublisher
        .sink { [weak self] in
          guard let self = self else { return }
          
          // If we're invalidating the cache then we need to set this to initial status again
          self.state = .initial
          // We're not gonna broadcast this change. If you do it'll wreak havoc with the content
          // list and nav view—where the nav link for the currently displayed detail view disappears
          // from underneath us. Instead we check the state of this repo each time the content
          // listing appears. This doesn't feel that great, but it's what seems to work.
        }
    }
  }
  
  func dynamicContentViewModel(for contentId: Int) -> DynamicContentViewModel {
    DynamicContentViewModel(
      contentId: contentId,
      repository: repository,
      downloadAction: downloadAction,
      syncAction: syncAction
    )
  }
  
  func childContentsViewModel(for contentId: Int) -> ChildContentsViewModel {
    // Default to using the cached version
    DataCacheChildContentsViewModel(
      parentContentId: contentId,
      downloadAction: downloadAction,
      syncAction: syncAction,
      repository: repository,
      service: contentsService
    )
  }
}
