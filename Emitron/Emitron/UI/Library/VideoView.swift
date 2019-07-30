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

struct VideoPlayerControllerRepresentable: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = VideoPlayerController
  
  let videoID: Int
  private let user: UserModel
  
  init(with videoID: Int, user: UserModel) {
    self.videoID = videoID
    self.user = user
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) -> VideoPlayerControllerRepresentable.UIViewControllerType {
    let videosMC = VideosMC(user: user)
    return VideoPlayerController(with: videoID, videosMC: videosMC)
  }
  
  func updateUIViewController(_ uiViewController: VideoPlayerControllerRepresentable.UIViewControllerType, context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) {
    //
  }
}

struct VideoView: View {
  
  let videoID: Int
  let user: UserModel
  
  var body: some View {
    VideoPlayerControllerRepresentable(with: videoID, user: user)
  }
}

#if DEBUG
struct VideoView_Previews: PreviewProvider {

  static var previews: some View {
    let user = AppDelegate.guardpost.currentUser!
    return VideoView(videoID: 2292, user: user)
  }
}
#endif
