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
import AVKit
import Combine

enum VideoPlaybackViewModelError: Error {
  case invalidOrMissingAttribute(String)
  
  var localizedDescription: String {
    switch self {
    case .invalidOrMissingAttribute(let attribute):
      return "VideoPlaybackViewModelError::invalidOrMissingAttribute::\(attribute)"
    }
  }
}

final class VideoPlaybackViewModel {
  private let initialContentId: Int
  private let repository: Repository
  private let videosService: VideosService
  private let contentsService: ContentsService
  private let progressEngine: ProgressEngine
  
  private var contentList = [VideoPlaybackState]()
  private var currentIndex = -1
  private var currentContent: VideoPlaybackState {
    contentList[currentIndex]
  }
  private var subscriptions = Set<AnyCancellable>()
  

  let player: AVQueuePlayer = AVQueuePlayer()
  private var playerTimeObserverToken: Any?
  var state: DataState = .initial
  
  init(contentId: Int, repository: Repository, videosService: VideosService, contentsService: ContentsService) {
    self.initialContentId = contentId
    self.repository = repository
    self.videosService = videosService
    self.contentsService = contentsService
    self.progressEngine = ProgressEngine(contentsService: contentsService, repository: repository)
    
    prepareSubscribers()
  }
  
  deinit {
    if let token = playerTimeObserverToken {
      player.removeTimeObserver(token)
    }
  }
  
  func reloadIfRequired() {
    guard state == .initial else { return }
    reload()
  }
  
  func reload() {
    do {
      state = .loading
      progressEngine.start()
      contentList = try repository.playlist(for: initialContentId)
      currentIndex = 0
      player.play()
      if let progression = currentContent.progression {
        enqueue(index: 0, startTime: Double(progression.progress))
      } else {
        enqueue(index: 0)
      }
    } catch {
      Failure
        .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to load playlist: \(error)")
        .log()
    }
  }
  
  func play() {
    self.progressEngine.playbackStarted()
  }
  
  private func prepareSubscribers() {
    if let token = playerTimeObserverToken {
      player.removeTimeObserver(token)
    }
    let interval = CMTime(seconds: 5, preferredTimescale: 100)
    playerTimeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
      guard let self = self else { return }
      self.handleTimeUpdate(time: time)
    }
  }
  
  private func handleTimeUpdate(time: CMTime) {
    // Update progress
    progressEngine.updateProgress(for: currentContent.content.id, progress: Int(time.seconds))
      .sink(receiveCompletion: { (completion) in
        if case .failure(let error) = completion {
          if case .simultaneousStreamsNotAllowed = error {
            // TODO: Display error
            self.player.pause()
          }
          Failure
          .viewModelAction(from: String(describing: type(of: self)), reason: "Error updating progress: \(error)")
          .log()
        }
      }) { [weak self] (updatedProgression) in
        guard let self = self else { return }
        self.update(progression: updatedProgression)
      }
      .store(in: &subscriptions)
    
    
    // Check whether we need to enqueue the next one yet
    if state == .loading || state == .loadingAdditional { return }
    guard let currentItem = player.currentItem else {
      return enqueueNext()
    }
    // Don't load the next one if we've already got another one ready to play
    guard player.items().last == currentItem else { return }
    // Preload the next video 10s from the end
    if (currentItem.duration - time).seconds < 10 {
      enqueueNext()
    }
  }
  
  private func enqueueNext() {
    guard currentIndex < contentList.endIndex else { return }

    enqueue(index: currentIndex + 1)
  }
  
  private func enqueue(index: Int, startTime: Double? = nil) {
    state = .loadingAdditional
    let nextContent = contentList[index]
    avItem(for: nextContent)
      .sink(receiveCompletion: { (completion) in
        switch completion {
        case .finished:
          self.state = .hasData
        case .failure(let error):
          self.state = .failed
          Failure
            .viewModelAction(from: String(describing: type(of: self)), reason: "Unable to enqueue next playlist item: \(error))")
            .log()
        }
      }) { (playerItem) in
        // Try to seek if needed
        if let startTime = startTime {
          playerItem.seek(to: CMTime(seconds: startTime, preferredTimescale: 100)) { [weak self] _ in
            guard let self = self else { return }
            self.player.insert(playerItem, after: nil)
          }
        } else {
          // Append it to the end of the player queue
          self.player.insert(playerItem, after: nil)
        }
        // Move the curent content item pointer
        self.currentIndex += 1
      }
      .store(in: &subscriptions)
  }
  
  private func avItem(for state: VideoPlaybackState) -> Future<AVPlayerItem, Error> {
    Future<AVPlayerItem, Error> { (promise) in
      // Is there a completed download?
      if let download = state.download,
        download.state == .complete,
        let localUrl = download.localUrl {
        return promise(.success(AVPlayerItem(url: localUrl)))
      }
      
      // We're gonna need to stream it.
      guard let videoIdentifier = state.content.videoIdentifier else {
        return promise(.failure(VideoPlaybackViewModelError.invalidOrMissingAttribute("videoIdentifier")))
      }
      
      self.videosService.getVideoStream(for: videoIdentifier) { (result) in
        switch result {
        case .failure(let error):
          return promise(.failure(error))
        case .success(let response):
          guard response.kind == .stream else { return promise(.failure(VideoPlaybackViewModelError.invalidOrMissingAttribute("Not A Stream"))) }
          return promise(.success(AVPlayerItem(url: response.url)))
        }
      }
    }
  }
  
  private func update(progression: Progression) {
    // Find appropriate playback state
    guard let contentIndex = contentList.firstIndex(where: { $0.content.id == progression.id }) else { return }
    
    let currentState = contentList[contentIndex]
    contentList[contentIndex] = VideoPlaybackState(
      content: currentState.content,
      progression: progression,
      download: currentState.download
    )
  }
}
