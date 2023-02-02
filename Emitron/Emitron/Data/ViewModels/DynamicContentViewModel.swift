// Copyright (c) 2022 Kodeco Inc

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
  private let downloadService: DownloadService
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
  
  init(
    contentID: Int,
    repository: Repository,
    downloadService: DownloadService,
    syncAction: SyncAction?,
    messageBus: MessageBus,
    settingsManager: SettingsManager,
    sessionController: SessionController
  ) {
    self.contentID = contentID
    self.repository = repository
    self.downloadService = downloadService
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
      Task { @MainActor in
        do {
          let result = try await downloadService.requestDownload(contentID: contentID) { [repository] contentID in
            do {
              return try repository.contentPersistableState(for: contentID)
            } catch {
              Failure
                .repositoryLoad(from: Self.self, reason: "Unable to locate persistable state in cache:  \(error)")
                .log()
              throw error
            }
          }

          switch result {
          case .downloadRequestedSuccessfully:
            break
          case .downloadRequestedButQueueInactive:
            messageBus.post(message: Message(level: .warning, message: .downloadRequestedButQueueInactive))
          }
        } catch {
          messageBus.post(message: Message(level: .error, message: error.localizedDescription))
        }
      }
    case .enqueued, .inProgress:
      Task { @MainActor in
        do {
          try await downloadService.cancelDownload(contentID: contentID)
          messageBus.post(message: Message(level: .success, message: .downloadCancelled))
        } catch {
          messageBus.post(message: Message(level: .error, message: error.localizedDescription))
        }
      }
    case .downloaded:
      return DownloadDeletionConfirmation(
        contentID: contentID,
        title: "Confirm Delete",
        message: "Are you sure you want to delete this download?"
      ) { [downloadService, messageBus, contentID] in
        Task { @MainActor in
          do {
            try await downloadService.deleteDownload(contentID: contentID)
            messageBus.post(message: Message(level: .success, message: .downloadDeleted))
          } catch {
            messageBus.post(message: Message(level: .error, message: error.localizedDescription))
          }
        }
      }
    case .notDownloadable:
      Task { @MainActor in
        do {
          try await downloadService.cancelDownload(contentID: contentID)
          messageBus.post(message: Message(level: .warning, message: .downloadReset))
        } catch {
          messageBus.post(message: Message(level: .error, message: error.localizedDescription))
        }
      }
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
  
  func videoPlaybackViewModel(
    apiClient: RWAPI,
    dismissClosure: @escaping () -> Void
  ) -> VideoPlaybackViewModel {
    let videosService = VideosService(networkClient: apiClient)
    let contentsService = ContentsService(networkClient: apiClient)
    return .init(
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
