/// Copyright (c) 2020 Razeware LLC
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
import Network

enum ProgressEngineError: Error {
  case simultaneousStreamsNotAllowed
  case upstreamError(Error)
  case notImplemented
  
  var localizedDescription: String {
    switch self {
    case .simultaneousStreamsNotAllowed:
      return "ProgressEngineError::SimulataneousStreamsNotAllowed"
    case .upstreamError(let error):
      return "ProgressEngineError::UpstreamError:: \(error)"
    case .notImplemented:
      return "ProgressEngineError::NotImplemented"
    }
  }
}

final class ProgressEngine {
  enum Mode {
    case online, offline
  }
  private let contentsService: ContentsService
  private let repository: Repository
  private var mode: Mode = .offline
  private let networkMonitor = NWPathMonitor()
  
  private var playbackToken = ""
  
  init(contentsService: ContentsService, repository: Repository) {
    self.contentsService = contentsService
    self.repository = repository
    setupSubscriptions()
  }
  
  deinit {
    networkMonitor.cancel()
    networkMonitor.pathUpdateHandler = nil
  }
  
  func playbackStarted() {
    // Don't especially care if we're in offline mode
    guard mode == .online else { return }
    // Need to refresh the plaback token
    contentsService.getBeginPlaybackToken { [weak self] (result) in
      guard let self = self else { return }
      switch result {
      case .failure(let error):
        Failure
          .fetch(from: String(describing: type(of: self)), reason: "Unable to fetch playback token: \(error)")
          .log()
      case .success(let token):
        self.playbackToken = token
      }
    }
  }
  
  func updateProgress(for contentId: Int, progress: Int) -> Future<Progression, ProgressEngineError> {
    switch mode {
    case .offline:
      // TODO: Need to implement an offline progress and watch stats tracking engine. Yippee.
      return Future { (promise) in
        promise(.failure(.notImplemented))
      }
    case .online:
      return Future { (promise) in
        self.contentsService.reportPlaybackUsage(for: contentId, progress: progress, playbackToken: self.playbackToken) { [weak self] (response) in
          guard let self = self else { return promise(.failure(.notImplemented)) }
          switch response {
          case .failure(let error):
            if case .requestFailed(_, let statusCode) = error, statusCode == 400 {
              // This is an invalid token
              return promise(.failure(.simultaneousStreamsNotAllowed))
            }
            // Some other error. Let's just send it back
            return promise(.failure(.upstreamError(error)))
          case .success(let (progression, cacheUpdate)):
            // Update the cache and return the updated progression
            self.repository.apply(update: cacheUpdate)
            return promise(.success(progression))
          }
        }
      }
    }
  }
  
  private func setupSubscriptions() {
    if networkMonitor.currentPath.status == .satisfied {
      self.mode = .online
    }
    networkMonitor.pathUpdateHandler = { [weak self] path in
      guard let self = self else { return }
      if path.status == .satisfied {
        self.mode = .online
      } else {
        self.mode = .offline
      }
    }
  }
}
