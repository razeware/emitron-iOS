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
    //setupNotification()
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
    removeUsageObserverToken()
    
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
      guard let content = self.content.first else { return }
      self.insertVideoStream(for: content)
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
        
        // TODO: Revisit downloads MC
//        if let downloadsMC = DataManager.current?.downloadsMC,
//          let downloadModel = downloadsMC.data.first(where: { $0.content.videoID == self.videoIDs.first! }) {
//          self.playFromLocalStorage(with: downloadModel.localPath)
//        } else {
//          guard let firstContent = self.content.first,
//            let videoID = firstContent.videoID else { return }
//          self.insertVideoStream(for: videoID, duration: firstContent.duration)
//        }
        guard let firstContent = self.content.first else { return }
        
        self.insertVideoStream(for: firstContent)
        
      } else {
        // TODO: Show failure message/view
      }
    }
  }
  
  private func setUpAVQueuePlayer(with item: AVPlayerItem) -> Void {
    let queuePlayer = AVQueuePlayer(items: [item])
    
    queuePlayer.play()
    queuePlayer.rate = UserDefaults.standard.playSpeed
    queuePlayer.appliesMediaSelectionCriteriaAutomatically = false
    
    avQueuePlayer = queuePlayer
  }
  
  private func playFromLocalStorage(with url: URL) {
    let doc = Document(fileURL: url)
    doc.open { [weak self] success in
      guard let self = self else { return }
      guard success else {
        fatalError("Failed to open doc.")
      }
      
      if let url = doc.videoData.url {
        self.player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
        self.player?.play()
        self.player?.rate = UserDefaults.standard.playSpeed
        self.player?.appliesMediaSelectionCriteriaAutomatically = true
        
        doc.close() { success in
          guard success else {
            fatalError("Failed to close doc.")
          }
        }
      }
    }
  }
  
  private func insertVideoStream(for content: ContentDetailsModel) {
    
    guard let videoID = content.videoID else { return }
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
          // Create player item
          let playerItem = self.createPlayerItem(for: url)
          
          // If the queuePlayer exists, then insert after current item
          if let qPlayer = self.avQueuePlayer {
            qPlayer.insert(playerItem, after: nil)
            
            // Kill current usage observer and start a new one
            self.removeUsageObserverToken()
            self.startProgressObservation(for: content.id)
            
          } else {
            self.setUpAVQueuePlayer(with: playerItem)
            self.startProgressObservation(for: content.id)
          }
          // Remove the played item from the contents array
          self.content.removeFirst()
        }
      }
    }
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
  
//  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//    if UIDevice.current.orientation.isLandscape {
//        print("Landscape")
//    } else {
//        print("Portrait")
//    }
//  }
}
