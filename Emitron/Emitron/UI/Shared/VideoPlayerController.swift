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
import AVFoundation
import UIKit
import AVKit

class VideoPlayerController: AVPlayerViewController {

  private var content: [ContentDetailsModel]
  private var videosMC: VideosMC
  private var usageTimeObserverToken: Any?
  private var autoplayNextTimeObserverToken: Any?
  private var avQueuePlayer: AVQueuePlayer? {
    didSet {
      self.player = avQueuePlayer
    }
  }

  init(with content: [ContentDetailsModel], videosMC: VideosMC) {
    self.videosMC = videosMC
    self.content = content
    super.init(nibName: nil, bundle: nil)
    setupNotification()
  }

  private func setupNotification() {
    NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                           object: nil,
                                           queue: .main,
                                           using: didRotate)

  }

  var didRotate: (Notification) -> Void = { notification in
    switch UIDevice.current.orientation {
    case .landscapeLeft, .landscapeRight:
      print("landscape")
    case .portrait, .portraitUpsideDown:
      print("Portrait")
    default:
      print("other")
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    player?.pause()

    //UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
  }

  private func removeUsageObserverToken() {
    if let usageObserverToken = usageTimeObserverToken {
      player?.removeTimeObserver(usageObserverToken)
      usageTimeObserverToken = nil
    }
  }

  deinit {

    NotificationCenter.default.removeObserver(self)
    removeUsageObserverToken()
  }

  @objc private func playerDidFinishPlaying() {
    DispatchQueue.main.async {
      self.playFromLocalIfPossible()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    entersFullScreenWhenPlaybackBegins = true

    videosMC.fetchBeginPlaybackToken { [weak self] (success, token)  in
      guard let self = self else {
        // TODO: Show failure message/view
        return
      }
      if success {
        // Start playback from local, if not fetch from remote
        DispatchQueue.main.async {
          self.playFromLocalIfPossible()
        }

      } else {
        // TODO: Show failure message/view
      }
    }
  }

  private func playFromLocalIfPossible() {
    guard let firstContent = content.first else { return }
    
    if let downloadsMC = DataManager.current?.downloadsMC,
      let downloadModel = downloadsMC.data.first(where: { $0.content.videoID == firstContent.videoID }) {
      playFromLocalStorage(with: downloadModel.localPath, contentDetails: firstContent)
    } else  {
      fetchAndInsertFromVideosRemote(for: firstContent)
    }
  }

  private func setUpAVQueuePlayer(with item: AVPlayerItem) -> Void {
    let queuePlayer = AVQueuePlayer(items: [item])

    queuePlayer.play()
    queuePlayer.rate = UserDefaults.standard.playSpeed
    queuePlayer.appliesMediaSelectionCriteriaAutomatically = false

    avQueuePlayer = queuePlayer
  }

  private func playFromLocalStorage(with url: URL, contentDetails: ContentDetailsModel) {
    let doc = Document(fileURL: url)
    doc.open { [weak self] success in
      guard let self = self else { return }
      guard success else {
        fatalError("Failed to open doc.")
      }

      if let url = doc.videoData.url {
        self.insertVideoStream(for: url, contentDetails: contentDetails)
      }
    }
  }

  private func fetchAndInsertFromVideosRemote(for contentDetails: ContentDetailsModel) {
    guard let videoID = contentDetails.videoID else { return }
    videosMC.getVideoStream(for: videoID) { [weak self] result in
      guard let self = self else {
        return
      }

      switch result {
      case .failure(let error):
        Failure
        .fetch(from: "VideeoPlayerControlelr_insert", reason: error.localizedDescription)
        .log(additionalParams: nil)
      case .success(let videoStream):

        if let url = videoStream.url {
          self.insertVideoStream(for: url, contentDetails: contentDetails)
        }
      }
    }
  }

  private func insertVideoStream(for url: URL, contentDetails: ContentDetailsModel) {
    // Create player item
    let playerItem = createPlayerItem(for: url)

    // If the queuePlayer exists, then insert after current item
    if let qPlayer = avQueuePlayer {
      qPlayer.insert(playerItem, after: nil)

      // Kill current usage observer and start a new one
      removeUsageObserverToken()
      startProgressObservation(for: contentDetails.id)

    } else {
      setUpAVQueuePlayer(with: playerItem)
      startProgressObservation(for: contentDetails.id)
    }
    // Remove the played item from the contents array
    content.removeFirst()
  }

  private func createPlayerItem(for url: URL) -> AVPlayerItem {
    let asset = AVAsset(url: url)
    let playerItem = AVPlayerItem(asset: asset)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.playerDidFinishPlaying),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: playerItem)

    if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
      let locale = Locale(identifier: "en")
      let options =
        AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
      if let option = options.first, UserDefaults.standard.closedCaptionOn {
        playerItem.select(option, in: group)
      }
    }
    return playerItem
  }

  private func startProgressObservation(for contentID: Int) {
    usageTimeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 5, preferredTimescale: 1), queue: DispatchQueue.main, using: { [weak self] progressTime in

      // When you stop the video, the progressTime becomes very large, so adding a check in order to see whether the progreess > .oneDay
      // which we will safely assume is not the actual progreess time
      let seconds = CMTimeGetSeconds(progressTime)
      guard let self = self, seconds < TimeInterval.oneDay else { return }

      self.videosMC.reportUsageStatistics(progress: Int(seconds), contentID: contentID)
    })
  }
}
