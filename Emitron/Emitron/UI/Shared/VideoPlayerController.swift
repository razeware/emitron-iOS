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

class VideoViewUIKit: UIView {
  
  var player: AVPlayer? {
    get {
      return playerLayer.player
    }
    
    set {
      playerLayer.player = newValue
    }
  }
  
  override class var layerClass: AnyClass {
    return AVPlayerLayer.self
  }
  
  var playerLayer: AVPlayerLayer {
    return layer as! AVPlayerLayer
  }
}

class VideoPlayerController: AVPlayerViewController {
  
  let videoID: Int
  private var videosMC: VideosMC
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .landscapeLeft
  }
  
  init(with videoID: Int, videosMC: VideosMC) {
    self.videoID = videoID
    self.videosMC = videosMC
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    player?.pause()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let downloadsMC = DataManager.current?.downloadsMC, let downloadModel = downloadsMC.data.first(where: { $0.content.videoID == videoID }) {
      print("downloadModel.localPath: \(downloadModel.localPath)")
      self.player = AVPlayer(url: downloadModel.localPath)
      self.player?.play()
    } else {
      videosMC.getVideoStream(for: videoID) { [weak self] result in
        guard let self = self else {
          return
        }
        
        switch result {
        case .failure(let error):
          print(error.localizedDescription)
        case .success(let videoStream):
          print(videoStream)
          if let url = videoStream.url {
            self.player = AVPlayer(url: url)
            self.player?.play()
          }
        }
      }
    }
  }
}
