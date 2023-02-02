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

import AVKit
import Combine

extension VideoPlaybackViewModel {
  enum Error: Swift.Error {
    case invalidOrMissingAttribute(String)
    case cannotStreamWhenOffline
    case invalidPermissions
    case expiredPermissions
    case unableToLoadArtwork

    var localizedDescription: String {
      switch self {
      case .invalidOrMissingAttribute(let attribute):
        return "VideoPlaybackViewModelError::invalidOrMissingAttribute::\(attribute)"
      case .cannotStreamWhenOffline:
        return .videoPlaybackCannotStreamWhenOffline
      case .invalidPermissions:
        return .videoPlaybackInvalidPermissions
      case .expiredPermissions:
        return .videoPlaybackExpiredPermissions
      case .unableToLoadArtwork:
        return "VideoPlaybackViewModelError::unableToLoadArtwork"
      }
    }

    var messageLevel: Message.Level {
      switch self {
      case .expiredPermissions:
        return .warning
      default:
        return .error
      }
    }

    var messageAutoDismiss: Bool {
      switch self {
      case .expiredPermissions:
        return true
      default:
        return false
      }
    }
  }
}

extension Notification.Name {
  static let requestReview = Self("requestReview")
}

final class VideoPlaybackViewModel {
  // Allow control of appearance and dismissal of the video view
  var shouldShow = false
  
  private let initialContentID: Int
  private let repository: Repository
  private let videosService: VideosService
  private let contentsService: ContentsService
  private let progressEngine: ProgressEngine
  private let sessionController: SessionController
  private let dismiss: () -> Void
  
  // These are the content models that this view model is capable of playing. In this order.
  private var contentList: [VideoPlaybackState] = []
  // A cache of playback items, and a way of finding the content model for the currently playing item
  private var playerItems: [Int: AVPlayerItem] = [:]
  private var currentlyPlayingContentID: Int? {
    guard let currentItem = player.currentItem,
      let contentID = playerItems.first(where: { $1 == currentItem })?.key
      else { return nil }
    return contentID
  }
  // Managing the Player queue. We enqueue stuff at the last possible moment.
  private var nextContentToEnqueueIndex = 0
  private var nextContentToEnqueue: VideoPlaybackState {
    contentList[nextContentToEnqueueIndex]
  }
  private var subscriptions = Set<AnyCancellable>()

  let player = AVQueuePlayer()
  let messageBus: MessageBus
  private var playerTimeObserverToken: Any?
  var state: DataState = .initial
  private var shouldBePlaying = false
  let settingsManager: SettingsManager
  
  init(
    contentID: Int,
    repository: Repository,
    videosService: VideosService,
    contentsService: ContentsService,
    syncAction: SyncAction?,
    sessionController: SessionController,
    messageBus: MessageBus,
    settingsManager: SettingsManager,
    dismissClosure: @escaping () -> Void = { }
  ) {
    initialContentID = contentID
    self.repository = repository
    self.videosService = videosService
    self.contentsService = contentsService
    self.settingsManager = settingsManager
    progressEngine = ProgressEngine(
      contentsService: contentsService,
      repository: repository,
      syncAction: syncAction
    )
    self.sessionController = sessionController
    self.messageBus = messageBus
    dismiss = dismissClosure
    
    prepareSubscribers()
  }
  
  deinit {
    if let token = playerTimeObserverToken {
      player.removeTimeObserver(token)
    }
  }
  
  func verifyCanPlay() throws {
    // Do we have a user
    guard let user = sessionController.user else {
      throw Error.invalidPermissions
    }
    // Do we have the first item of content?
    guard let contentItem = contentList.first else {
      throw Error.invalidPermissions
    }
    // Can that user view this content?
    if contentItem.content.professional && !user.canStreamPro {
      throw Error.invalidPermissions
    }
    // If we're online then, that's all good
    if sessionController.sessionState == .online {
      return
    }
    
    // If we've got a download, then we might be ok
    if let download = contentItem.download,
      download.state == .complete,
      download.localURL != nil {
      // We have a download, but are we still authenticated?
      guard sessionController.hasCurrentDownloadPermissions
      else { throw Error.expiredPermissions }
    } else {
      // We can't stream cos we're offline, and we don't have a download
      throw Error.cannotStreamWhenOffline
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
      contentList = try repository.playlist(for: initialContentID)
      nextContentToEnqueueIndex = 0
      if let progression = nextContentToEnqueue.progression,
        !progression.finished {
        enqueue(index: 0, startTime: Double(progression.progress))
      } else {
        enqueue(index: 0)
      }
    } catch {
      Failure
        .viewModelAction(from: Self.self, reason: "Unable to load playlist: \(error)")
        .log()
    }
  }
  
  func play() {
    progressEngine.playbackStarted()
    shouldBePlaying = true
  }
  
  func pause() {
    shouldBePlaying = false
    player.pause()
  }

  func stop() {
    self.shouldBePlaying = false
    self.player.pause()
  }
}

// MARK: - private
private extension VideoPlaybackViewModel {
  func prepareSubscribers() {
    if let token = playerTimeObserverToken {
      player.removeTimeObserver(token)
    }
    let interval = CMTime(
      seconds: .init(.videoPlaybackProgressTrackingInterval),
      preferredTimescale: 100
    )
    playerTimeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self = self else { return }
      self.handleTimeUpdate(time: time)
    }
    
    player.publisher(for: \.rate)
      .removeDuplicates()
      .sink { [weak self] rate in
        self?.shouldBePlaying = rate == 0
        
        guard
          let self = self,
          ![0, self.settingsManager.playbackSpeed.rate].contains(rate)
        else { return }
        
        self.player.rate = self.settingsManager.playbackSpeed.rate
      }
      .store(in: &subscriptions)
    
    player.publisher(for: \.currentItem?.status)
      .removeDuplicates()
      .sink { [weak self] status in
        guard
          let self = self,
          case .readyToPlay = status,
          self.shouldBePlaying,
          self.player.rate == 0
        else { return }

        self.player.play()
      }
      .store(in: &subscriptions)
    
    settingsManager
      .playbackSpeedPublisher
      .removeDuplicates()
      .sink { [weak self] playbackSpeed in
        self?.player.rate = playbackSpeed.rate
      }
      .store(in: &subscriptions)
    
    settingsManager
      .closedCaptionOnPublisher
      .removeDuplicates()
      .sink { [weak self] _ in
        guard let self = self else { return }

        self.player.currentItem.map(self.addClosedCaptions)
      }
      .store(in: &subscriptions)
    
    NotificationCenter.default
      .publisher(for: .AVPlayerItemDidPlayToEndTime)
      .sink { [weak self] _ in
        guard let self = self else { return }
        if self.player.currentItem == self.player.items().last {
          // We're done. Let's dismiss the player
          self.dismiss()
        }
      }
      .store(in: &subscriptions)
  }

  func handleTimeUpdate(time: CMTime) {
    guard let currentlyPlayingContentID = currentlyPlayingContentID else { return }

    // Update progress
    Task {
      do {
        update(
          progression: try await progressEngine.updateProgress(
            for: currentlyPlayingContentID,
            progress: Int(time.seconds)
          )
        )
      } catch {
        if case ProgressEngineError.simultaneousStreamsNotAllowed = error {
          messageBus.post(message: .init(level: .error, message: .simultaneousStreamsError))
          await player.pause()
        }
        Failure
          .viewModelAction(from: Self.self, reason: "Error updating progress: \(error)")
          .log()
      }
    }
    
    // Check whether we need to enqueue the next one yet
    if state == .loading || state == .loadingAdditional {
      return
    }
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
  
  func enqueueNext() {
    guard nextContentToEnqueueIndex < contentList.endIndex else { return }
    enqueue(index: nextContentToEnqueueIndex)
  }
  
  func enqueue(index: Int, startTime: Double? = nil) {
    state = .loadingAdditional
    let nextContent = contentList[index]

    guard sessionController.canPlay(content: nextContent.content) else {
      // This user doesn't have permission to play this content. So skip to the next.
      nextContentToEnqueueIndex += 1
      return enqueueNext()
    }

    Task {
      do {
        let playerItem = try await avItem(for: nextContent)
        // Try to seek if needed
        if let startTime = startTime {
          await playerItem.seek(to: .init(seconds: startTime, preferredTimescale: 100))
        }

        // Append it to the end of the player queue
        player.insert(playerItem, after: nil)
        
        // Move the current content item pointer
        nextContentToEnqueueIndex += 1
        state = .hasData
      } catch {
        state = .failed
        Failure
          .viewModelAction(from: Self.self, reason: "Unable to enqueue next playlist item: \(error))")
          .log()
      }
    }
  }
  
  func avItem(for state: VideoPlaybackState) async throws -> AVPlayerItem {
    // Do we already have it it in cache?
    if let item = playerItems[state.content.id] {
      return item
    }

    // Is there a completed download?
    if
      let download = state.download,
      download.state == .complete,
      let localURL = download.localURL
    {
      let item = AVPlayerItem(asset: AVURLAsset(url: localURL))
      addMetadata(from: state, to: item)
      addClosedCaptions(for: item)
      // Add it to the cache
      playerItems[state.content.id] = item
      return item
    }
      
    // We're gonna need to stream it.
    guard let videoIdentifier = state.content.videoIdentifier else {
      throw Error.invalidOrMissingAttribute("videoIdentifier")
    }

    let attachment = try await videosService.videoStream(for: videoIdentifier)

    guard attachment.kind == .stream
    else { throw Error.invalidOrMissingAttribute("Not A Stream") }

    let item = AVPlayerItem(url: attachment.url)
    self.addMetadata(from: state, to: item)
    self.addClosedCaptions(for: item)
    // Add it to the cache
    self.playerItems[state.content.id] = item
    return item
  }
  
  func addClosedCaptions(for playerItem: AVPlayerItem) {
    if let group = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
      let locale = Locale(identifier: "en")
      let options =
        AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
      if let option = options.first, settingsManager.closedCaptionOn {
        playerItem.select(option, in: group)
      } else {
        playerItem.select(nil, in: group)
      }
    }
  }
  
  func addMetadata(from state: VideoPlaybackState, to playerItem: AVPlayerItem) {
    let title = AVMutableMetadataItem()
    title.identifier = .commonIdentifierTitle
    title.value = state.content.name as NSString
    
    let description = AVMutableMetadataItem()
    description.identifier = .commonIdentifierDescription
    description.value = state.content.descriptionPlainText as NSString
    
    let artwork = AVMutableMetadataItem()
    artwork.identifier = .commonIdentifierArtwork

    let deferredArtwork = AVMetadataItem(propertiesOf: artwork) { request in
      guard let url = state.content.cardArtworkURL else {
        request.respond(error: Error.unableToLoadArtwork)
        return
      }

      Task {
        request.respond(
          value: try await URLSession.shared.data(from: url).0 as NSData
        )
      }
    }
    
    playerItem.externalMetadata = [title, description, deferredArtwork]
  }

  func update(progression: Progression) {
    // Find appropriate playback state
    guard let contentIndex = (contentList.firstIndex { $0.content.id == progression.id })
    else { return }
    
    let currentState = contentList[contentIndex]
    contentList[contentIndex] = VideoPlaybackState(
      content: currentState.content,
      progression: progression,
      download: currentState.download
    )
  }
}
