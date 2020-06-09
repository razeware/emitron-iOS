// Copyright (c) 2020 Razeware LLC
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
import class Foundation.RunLoop

final class DynamicContentViewModel: ObservableObject, DynamicContentDisplayable {
  private let contentId: Int
  private let repository: Repository
  private let downloadAction: DownloadAction
  private weak var syncAction: SyncAction?
  
  private var dynamicContentState: DynamicContentState?
  
  var state: DataState = .initial
  @Published var viewProgress: ContentViewProgressDisplayable = .notStarted
  @Published var downloadProgress: DownloadProgressDisplayable = .notDownloadable
  @Published var bookmarked: Bool = false
  
  private var subscriptions = Set<AnyCancellable>()
  private var downloadActionSubscriptions = Set<AnyCancellable>()
  
  init(contentId: Int, repository: Repository, downloadAction: DownloadAction, syncAction: SyncAction?) {
    self.contentId = contentId
    self.repository = repository
    self.downloadAction = downloadAction
    self.syncAction = syncAction
  }
  
  func initialiseIfRequired() {
    if state == .initial {
      reload()
    }
  }
  
  func reload() {
    self.state = .loading
    subscriptions.forEach({ $0.cancel() })
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  private func configureSubscriptions() {
    repository
      .contentDynamicState(for: contentId)
      .removeDuplicates()
      .sink(receiveCompletion: { [weak self] completion in
        self?.state = .failed
        Failure
          .repositoryLoad(from: "DynamicContentViewModel", reason: "Unable to retrieve dynamic download content: \(completion)")
          .log()
      }) { [weak self] contentState in
        guard let self = self else { return }

        self.viewProgress = ContentViewProgressDisplayable(progression: contentState.progression)
        self.downloadProgress = DownloadProgressDisplayable(download: contentState.download)
        self.bookmarked = contentState.bookmark != nil
        self.dynamicContentState = contentState
        self.state = .hasData
      }
      .store(in: &subscriptions)
  }
  
  func downloadTapped() -> DownloadDeletionConfirmation? {
    guard state == .hasData else { return nil }
    
    switch downloadProgress {
    case .downloadable:
      downloadAction.requestDownload(contentId: contentId) { contentId -> (ContentPersistableState?) in
        do {
          return try self.repository.contentPersistableState(for: contentId)
        } catch {
          Failure
            .repositoryLoad(from: String(describing: type(of: self)), reason: "Unable to locate presistable state in cache:  \(error)")
            .log()
          return nil
        }
      }
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          MessageBus.current.post(message: Message(level: .error, message: error.localizedDescription))
        }
      }) { result in
        switch result {
        case .downloadRequestedSuccessfully:
          MessageBus.current.post(message: Message(level: .success, message: Constants.downloadRequestedSuccessfully))
        case .downloadRequestedButQueueInactive:
          MessageBus.current.post(message: Message(level: .warning, message: Constants.downloadRequestedButQueueInactive))
        }
      }
      .store(in: &downloadActionSubscriptions)

    case .enqueued, .inProgress:
      downloadAction.cancelDownload(contentId: contentId)
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
          if case .failure(let error) = completion {
            MessageBus.current.post(message: Message(level: .error, message: error.localizedDescription))
          }
        }) { _ in
          MessageBus.current.post(message: Message(level: .success, message: Constants.downloadCancelled))
        }
        .store(in: &downloadActionSubscriptions)
      
    case .downloaded:
      return DownloadDeletionConfirmation(
        contentId: contentId,
        title: "Confirm Delete",
        message: "Are you sure you want to delete this download?"
      ) { [weak self] in
        guard let self = self else { return }
        
        self.downloadAction.deleteDownload(contentId: self.contentId)
          .receive(on: RunLoop.main)
          .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
              MessageBus.current.post(message: Message(level: .error, message: error.localizedDescription))
            }
          }) { _ in
            MessageBus.current.post(message: Message(level: .success, message: Constants.downloadDeleted))
          }
        .store(in: &self.downloadActionSubscriptions)
      }
      
    case .notDownloadable:
      downloadAction.cancelDownload(contentId: contentId)
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
          if case .failure(let error) = completion {
            MessageBus.current.post(message: Message(level: .error, message: error.localizedDescription))
          }
        }) { _ in
          MessageBus.current.post(message: Message(level: .warning, message: Constants.downloadReset))
        }
        .store(in: &downloadActionSubscriptions)
    }
    return nil
  }
  
  func bookmarkTapped() {
    guard state == .hasData,
      let syncAction = syncAction else { return }
    
    if bookmarked {
      do {
        try syncAction.deleteBookmark(for: contentId)
        MessageBus.current.post(message: Message(level: .success, message: Constants.bookmarkDeleted))
      } catch {
        MessageBus.current.post(message: Message(level: .error, message: Constants.bookmarkDeletedError))
        Failure
          .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to delete bookmark: \(error)")
          .log()
      }
    } else {
      do {
        try syncAction.createBookmark(for: contentId)
        MessageBus.current.post(message: Message(level: .success, message: Constants.bookmarkCreated))
      } catch {
        MessageBus.current.post(message: Message(level: .error, message: Constants.bookmarkCreatedError))
        Failure
          .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to create bookmark: \(error)")
          .log()
      }
    }
  }
  
  func completedTapped() {
    guard state == .hasData,
      let syncAction = syncAction else { return }
    
    if case .completed = viewProgress {
      do {
        try syncAction.removeProgress(for: contentId)
        MessageBus.current.post(message: Message(level: .success, message: Constants.progressRemoved))
      } catch {
        MessageBus.current.post(message: Message(level: .error, message: Constants.progressRemovedError))
        Failure
          .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to delete progress: \(error)")
          .log()
      }
    } else {
      do {
        try syncAction.markContentAsComplete(contentId: contentId)
        MessageBus.current.post(message: Message(level: .success, message: Constants.progressMarkedAsComplete))
      } catch {
        MessageBus.current.post(message: Message(level: .error, message: Constants.progressMarkedAsCompleteError))
        Failure
          .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to mark as complete: \(error)")
          .log()
      }
    }
  }
  
  func videoPlaybackViewModel(apiClient: RWAPI, dismissClosure: @escaping () -> Void) -> VideoPlaybackViewModel {
    let videosService = VideosService(client: apiClient)
    let contentsService = ContentsService(client: apiClient)
    return VideoPlaybackViewModel(
      contentId: contentId,
      repository: repository,
      videosService: videosService,
      contentsService: contentsService,
      syncAction: syncAction,
      dismissClosure: dismissClosure
    )
  }
}
