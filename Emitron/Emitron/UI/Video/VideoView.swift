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

import SwiftUI
import AVKit

struct VideoPlayerControllerRepresentable: UIViewControllerRepresentable {  
  private let viewModel: VideoPlaybackViewModel
  
  init(with viewModel: VideoPlaybackViewModel) {
    self.viewModel = viewModel
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) -> AVPlayerViewController {
    let viewController = AVPlayerViewController()
    viewController.player = viewModel.player
    viewModel.play()
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: VideoPlayerControllerRepresentable.UIViewControllerType, context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) {
    // No-op
  }
}

struct VideoView: View {
  var viewModel: VideoPlaybackViewModel
  
  @Environment(\.presentationMode) var presentationMode
  
  @State private var settingsPresented: Bool = false
  @State private var playbackVerified: Bool = false

  var body: some View {
    viewModel.reloadIfRequired()
    verifyVideoPlaybackAllowed()
    return videoView
      .navigationBarItems(trailing:
        SwiftUI.Group {
          Button(action: {
            self.settingsPresented = true
          }) {
            Image("settings")
              .foregroundColor(.iconButton)
          }
        })
      .sheet(isPresented: self.$settingsPresented) {
        SettingsView(showLogoutButton: false)
      }
      .onDisappear {
        // Only pause the video if we've dismissed the video.
        // Otherwise, we pause it when we switch to full screen.
        guard !self.presentationMode.wrappedValue.isPresented else { return }
        
        self.viewModel.player.pause()
      }
  }
  
  private var videoView: some View {
    VideoPlayerControllerRepresentable(with: viewModel)
  }
  
  private func verifyVideoPlaybackAllowed() {
    guard !playbackVerified else { return }
    do {
      if try viewModel.canPlayOrDisplayError() {
        playbackVerified = true
      }
    } catch {
      if let viewModelError = error as? VideoPlaybackViewModelError {
        MessageBus.current.post(message: Message(level: .error, message: viewModelError.localizedDescription, autoDismiss: false))
      }
    }
  }
}
