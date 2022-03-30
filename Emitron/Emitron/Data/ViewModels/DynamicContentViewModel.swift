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

import SwiftUI
import Combine
import class Foundation.RunLoop

final class DynamicContentViewModel: ObservableObject, DynamicContentDisplayable {
  private let contentID: Int
  private let repository: Repository
  private let downloadAction: DownloadAction
  private weak var syncAction: SyncAction?
  private let messageBus: MessageBus
  private let settingsManager: SettingsManager
  private let sessionController: SessionController
  
  private var dynamicContentState: DynamicContentState?
  
  var state: DataState = .initial
  @Published var viewProgress: ContentViewProgressDisplayable = .notStarted
  @Published var downloadProgress: DownloadProgressDisplayable = .notDownloadable
  @Published var bookmarked = false

  private var subscriptions = Set<AnyCancellable>()
  private var downloadActionSubscriptions = Set<AnyCancellable>()
  
  init(contentID: Int, repository: Repository, downloadAction: DownloadAction, syncAction: SyncAction?, messageBus: MessageBus, settingsManager: SettingsManager, sessionController: SessionController) {
    self.contentID = contentID
    self.repository = repository
    self.downloadAction = downloadAction
    self.syncAction = syncAction
    self.messageBus = messageBus
    self.settingsManager = settingsManager
    self.sessionController = sessionController
  }
  
  func initialiseIfRequired() {
    if state == .initial {
      reload()
    }
  }
  
  func reload() {
    state = .loading
    subscriptions.forEach({ $0.cancel() })
    subscriptions.removeAll()
    configureSubscriptions()
  }
  
  func downloadTapped() -> DownloadDeletionConfirmation? {
    guard state == .hasData else { return nil }
    
    switch downloadProgress {
    case .downloadable:
      downloadAction.requestDownload(contentID: contentID) { contentID -> (ContentPersistableState?) in
        do {
          return try self.repository.contentPersistableState(for: contentID)
        } catch {
          Failure
            .repositoryLoad(from: Self.self, reason: "Unable to locate persistable state in cache:  \(error)")
            .log()
          return nil
        }
      }
      .receive(on: RunLoop.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure(let error) = completion {
            self?.messageBus.post(message: Message(level: .error, message: error.localizedDescription))
          }
        }
      ) { [weak self] result in
        switch result {
        case .downloadRequestedSuccessfully:
          break
        case .downloadRequestedButQueueInactive:
          self?.messageBus.post(message: Message(level: .warning, message: .downloadRequestedButQueueInactive))
        }
      }
      .store(in: &downloadActionSubscriptions)

    case .enqueued, .inProgress:
      downloadAction.cancelDownload(contentID: contentID)
        .receive(on: RunLoop.main)
        .sink(
          receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
              self?.messageBus.post(message: Message(level: .error, message: error.localizedDescription))
            }
          }
        ) { [weak self] _ in
          self?.messageBus.post(message: Message(level: .success, message: .downloadCancelled))
        }
        .store(in: &downloadActionSubscriptions)
      
    case .downloaded:
      return DownloadDeletionConfirmation(
        contentID: contentID,
        title: "Confirm Delete",
        message: "Are you sure you want to delete this download?"
      ) { [weak self] in
        guard let self = self else { return }
        
        self.downloadAction.deleteDownload(contentID: self.contentID)
          .receive(on: RunLoop.main)
          .sink(
            receiveCompletion: { [weak self] completion in
              if case .failure(let error) = completion {
                self?.messageBus.post(message: Message(level: .error, message: error.localizedDescription))
              }
            }
          ) { [weak self] _ in
            self?.messageBus.post(message: Message(level: .success, message: .downloadDeleted))
          }
          .store(in: &self.downloadActionSubscriptions)
      }
      
    case .notDownloadable:
      downloadAction.cancelDownload(contentID: contentID)
        .receive(on: RunLoop.main)
        .sink(
          receiveCompletion: { [weak self] completion in
            if case .failure(let error) = completion {
              self?.messageBus.post(message: Message(level: .error, message: error.localizedDescription))
            }
          }
        ) { [weak self] _ in
          self?.messageBus.post(message: Message(level: .warning, message: .downloadReset))
        }
        .store(in: &downloadActionSubscriptions)
    }
    return nil
  }
  
  func bookmarkTapped() {
    guard
      state == .hasData,
      let syncAction = syncAction
    else { return }
    
    if bookmarked {
      do {
        try syncAction.deleteBookmark(for: contentID)
      } catch {
        messageBus.post(message: Message(level: .error, message: .bookmarkDeletedError))
        Failure
          .viewModelAction(from: Self.self, reason: "Unable to delete bookmark: \(error)")
          .log()
      }
    } else {
      do {
        try syncAction.createBookmark(for: contentID)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
      } catch {
        messageBus.post(message: Message(level: .error, message: .bookmarkCreatedError))
        Failure
          .viewModelAction(from: Self.self, reason: "Unable to create bookmark: \(error)")
          .log()
      }
    }
  }
  
  func completedTapped() {
    guard state == .hasData,
      let syncAction = syncAction else { return }
    
    if case .completed = viewProgress {
      do {
        try syncAction.removeProgress(for: contentID)
        messageBus.post(message: Message(level: .success, message: .progressRemoved))
      } catch {
        messageBus.post(message: Message(level: .error, message: .progressRemovedError))
        Failure
          .viewModelAction(from: Self.self, reason: "Unable to delete progress: \(error)")
          .log()
      }
    } else {
      do {
        try syncAction.markContentAsComplete(contentID: contentID)
        messageBus.post(message: Message(level: .success, message: .progressMarkedAsComplete))
      } catch {
        messageBus.post(message: Message(level: .error, message: .progressMarkedAsCompleteError))
        Failure
          .viewModelAction(from: Self.self, reason: "Unable to mark as complete: \(error)")
          .log()
      }
    }
  }
  
  func videoPlaybackViewModel(apiClient: RWAPI, dismissClosure: @escaping () -> Void) -> VideoPlaybackViewModel {
    let videosService = VideosService(client: apiClient)
    let contentsService = ContentsService(client: apiClient)
    return VideoPlaybackViewModel(
      contentID: contentID,
      repository: repository,
      videosService: videosService,
      contentsService: contentsService,
      syncAction: syncAction,
      sessionController: sessionController,
      messageBus: messageBus,
      settingsManager: settingsManager,
      dismissClosure: dismissClosure
    )
  }
}

// MARK: - private
private extension DynamicContentViewModel {
  func configureSubscriptions() {
    repository
      .contentDynamicState(for: contentID)
      .removeDuplicates()
      .sink(
        receiveCompletion: { [weak self] completion in
          self?.state = .failed
          Failure
            .repositoryLoad(from: Self.self, reason: "Unable to retrieve dynamic download content: \(completion)")
            .log()
        }
      ) { [weak self] contentState in
        guard let self = self else { return }
        
        self.viewProgress = ContentViewProgressDisplayable(progression: contentState.progression)
        self.downloadProgress = DownloadProgressDisplayable(download: contentState.download)
        self.bookmarked = contentState.bookmark != nil
        self.dynamicContentState = contentState
        self.state = .hasData
      }
      .store(in: &subscriptions)
  }
}
