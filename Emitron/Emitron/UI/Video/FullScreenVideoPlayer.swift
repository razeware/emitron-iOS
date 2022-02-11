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
import AVKit

/// - Note: Could be  simplified to `AVKit.VideoPlayer` using `fullScreenCover`
/// if a dismissal button were included  with that, as `AVPlayerViewController` provides.
struct FullScreenVideoPlayer {
  init(
    model: VideoPlaybackViewModel,
    messageBus: MessageBus,
    handleDismissal: @escaping () -> Void
  ) throws {
    model.reloadIfRequired()

    do {
      try model.verifyCanPlay()
    } catch {
      if let viewModelError = error as? VideoPlaybackViewModel.Error {
        messageBus.post(
          message: .init(
            level: viewModelError.messageLevel,
            message: viewModelError.localizedDescription,
            autoDismiss: viewModelError.messageAutoDismiss
          )
        )
      }

      throw error
    }

    self.model = model
    self.handleDismissal = handleDismissal
  }

  private let model: VideoPlaybackViewModel
  private let handleDismissal: () -> Void
}

// MARK: - UIViewControllerRepresentable
extension FullScreenVideoPlayer: UIViewControllerRepresentable {
  /// - Bug: This is a View Controller because without presenting an `AVPlayerViewController`,
  /// specifically in `viewDidAppear` and no earlier,
  /// the user will have to press the "expand to fullscreen (↕️)" button once to get it to change into a dismissal (❎) button,
  /// even through the player is already in fullscreen mode.
  ///
  /// This also explains why `Presenter` is the `UIViewControllerType` of this `UIViewControllerRepresentable`,
  /// instead of `AVPlayerViewController` (with this type being a `Coordinator` `NSObject` instead, purely for delegation).
  final class Presenter: UIViewController {
    // swiftlint:disable:next strict_fileprivate
    fileprivate init(
      model: VideoPlaybackViewModel,
      handleDismissal: @escaping () -> Void
    ) {
      self.model = model
      self.handleDismissal = handleDismissal
      super.init(nibName: nil, bundle: nil)
    }

    private let model: VideoPlaybackViewModel
    private let handleDismissal: () -> Void
    private var playerIsPresented = false

    @available(*, unavailable) required init?(coder: NSCoder) {
      preconditionFailure("init(coder:) has not been implemented")
    }
  }

  func makeUIViewController(context: Context) -> Presenter {
    .init(
      model: model,
      handleDismissal: handleDismissal
    )
  }

  func updateUIViewController(_: UIViewControllerType, context _: Context) { }
}

extension FullScreenVideoPlayer.Presenter {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if !playerIsPresented {
      let viewController = AVPlayerViewController()
      viewController.player = model.player
      viewController.delegate = self
      present(viewController, animated: true)
      playerIsPresented = true
      model.play()
    }
  }
}

// MARK: - AVPlayerViewControllerDelegate
extension FullScreenVideoPlayer.Presenter: AVPlayerViewControllerDelegate {
  func playerViewController(
    _: AVPlayerViewController,
    willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator
  ) {
    model.stop()
    handleDismissal()
  }
}
