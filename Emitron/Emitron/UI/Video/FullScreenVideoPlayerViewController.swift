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

import UIKit
import AVKit
import SwiftUI

class FullScreenVideoPlayerViewController: UIViewController {
  @Binding var viewModel: VideoPlaybackViewModel?
  private var isFullscreen: Bool = false
  
  init(viewModel: Binding<VideoPlaybackViewModel?>) {
    self._viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
    
    self.viewModel?.reloadIfRequired()
    self.verifyVideoPlaybackAllowed()
  }

  required init?(coder: NSCoder) {
    preconditionFailure("init(coder:) has not been implemented")
  }
}

extension FullScreenVideoPlayerViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !isFullscreen {
      let viewController = AVPlayerViewController()
      viewController.player = viewModel?.player
      viewController.delegate = self
      present(viewController, animated: true)
      viewModel?.play()
    }
  }
}

extension FullScreenVideoPlayerViewController {
  private func verifyVideoPlaybackAllowed() {
    do {
      try viewModel?.verifyCanPlay()
    } catch {
      if let viewModelError = error as? VideoPlaybackViewModel.Error {
        MessageBus.current.post(
          message: Message(
            level: viewModelError.messageLevel,
            message: viewModelError.localizedDescription,
            autoDismiss: viewModelError.messageAutoDismiss
          )
        )
      }
      disappear()
    }
  }
  
  private func disappear() {
    dismiss(animated: true) {
      self.viewModel = nil
    }
  }
}

extension FullScreenVideoPlayerViewController: AVPlayerViewControllerDelegate {
  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    isFullscreen = true
  }
  
  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: nil) { context in
      guard !context.isCancelled else { return }
      // Exited fullscreen, so let's disappear ourselves
      self.disappear()
    }
  }
}
