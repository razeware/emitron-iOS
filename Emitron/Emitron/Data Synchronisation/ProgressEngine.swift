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

import Combine
import Foundation
import Network

enum ProgressEngineError: Error {
  case simultaneousStreamsNotAllowed
  case upstreamError(Error)
  case notImplemented
  
  var localizedDescription: String {
    switch self {
    case .simultaneousStreamsNotAllowed:
      return "ProgressEngineError::SimultaneousStreamsNotAllowed"
    case .upstreamError(let error):
      return "ProgressEngineError::UpstreamError:: \(error)"
    case .notImplemented:
      return "ProgressEngineError::NotImplemented"
    }
  }
}

final class ProgressEngine {
  enum Mode {
    case online
    case offline
  }
  
  private let contentsService: ContentsService
  private let repository: Repository
  private weak var syncAction: SyncAction?
  private var mode: Mode = .offline
  private let networkMonitor = NWPathMonitor()
  
  private var playbackToken: String?
  
  init(contentsService: ContentsService, repository: Repository, syncAction: SyncAction?) {
    self.contentsService = contentsService
    self.repository = repository
    self.syncAction = syncAction
  }
  
  deinit {
    networkMonitor.cancel()
    networkMonitor.pathUpdateHandler = nil
  }
  
  func start() {
    networkMonitor.start(queue: .global(qos: .utility))
    setupSubscriptions()
  }
  
  func playbackStarted() {
    // Don't especially care if we're in offline mode
    guard mode == .online else { return }
    playbackToken = nil
    // Need to refresh the playback token
    Task {
      do {
        playbackToken = try await contentsService.beginPlaybackToken
      } catch {
        Failure
          .fetch(from: Self.self, reason: "Unable to fetch playback token: \(error)")
          .log()
      }
    }
  }
  
  func updateProgress(for contentID: Int, progress: Int) async throws -> Progression {
    let progression = updateCacheWithProgress(for: contentID, progress: progress)
    
    switch mode {
    case .offline:
      try syncAction?.updateProgress(for: contentID, progress: progress)
      try syncAction?.recordWatchStats(for: contentID, secondsWatched: .videoPlaybackProgressTrackingInterval)

      return progression
    case .online:
      // Don't bother trying if the playback token is empty.
      guard let playbackToken else { return progression }

      let (progression, cacheUpdate) = try await contentsService.reportPlaybackUsage(
        for: contentID,
        progress: progress,
        playbackToken: playbackToken
      )

      // Update the cache and return the updated progression
      repository.apply(update: cacheUpdate)
      // Do we need to update the parent?
      if
        let parentContent = repository.parentContent(for: contentID),
        let childProgressUpdate = repository.childProgress(for: parentContent.id),
        var existingProgression = repository.progression(for: parentContent.id)
      {
        existingProgression.progress = childProgressUpdate.completed
        repository.apply(update: .init(progressions: [existingProgression]))
      }

      return progression
    }
  }
  
  private func setupSubscriptions() {
    if case .satisfied = networkMonitor.currentPath.status {
      mode = .online
    }
    networkMonitor.pathUpdateHandler = { [weak self] path in
      self?.mode = path.status == .satisfied ? .online : .offline
    }
  }
  
  @discardableResult private func updateCacheWithProgress(
    for contentID: Int,
    progress: Int,
    target: Int? = nil
  ) -> Progression {
    let content = repository.content(for: contentID)
    let progression: Progression
    
    if var existingProgression = repository.progression(for: contentID) {
      existingProgression.progress = progress
      progression = existingProgression
    } else {
      progression = Progression(
        id: -1,
        target: target ?? content?.duration ?? 0,
        progress: progress,
        createdAt: .now,
        updatedAt: .now,
        contentID: contentID
      )
    }
    
    let cacheUpdate = DataCacheUpdate(progressions: [progression])
    repository.apply(update: cacheUpdate)
    
    // See whether we need to update parent content
    if progression.finished,
      let parentContent = repository.parentContent(for: contentID),
      let childProgress = repository.childProgress(for: parentContent.id) {
      updateCacheWithProgress(for: parentContent.id, progress: childProgress.completed, target: childProgress.total)
    }
    
    return progression
  }
}
