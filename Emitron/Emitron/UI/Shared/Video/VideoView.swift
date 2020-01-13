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
    
  private let contentDetails: [ContentListDisplayable]
  private let user: User
  
  init(with contentDetails: [ContentListDisplayable], user: User) {
    self.contentDetails = contentDetails
    self.user = user
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) -> VideoPlayerController {
    let videosMC = VideosMC(user: user)
    return VideoPlayerController(with: contentDetails, videosMC: videosMC)
  }
  
  func updateUIViewController(_ uiViewController: VideoPlayerControllerRepresentable.UIViewControllerType, context: UIViewControllerRepresentableContext<VideoPlayerControllerRepresentable>) {
    // N/A
  }
}

struct VideoView: View {
  
  let contentDetails: [ContentListDisplayable]
  let user: User
  @State var showingProSheet = false
  var onDisappear: (() -> Void)?
  @State private var settingsPresented: Bool = false
  
  var body: some View {
    contentView
      .onDisappear {
        // When the VideoView disappears, we trigger a reload of the content details, so that the
        // progressions are shown correctly.
        self.onDisappear?()
      }
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
      .alert(isPresented: $showingProSheet) {
        notProAlert
      }
  }
  
  private var contentView: AnyView {
    if !user.canStreamPro && contentDetails.first?.professional ?? true {
      return AnyView(Color.backgroundColor)
    } else {
      return videoView
    }
  }
  
  private var videoView: AnyView {
    AnyView(VideoPlayerControllerRepresentable(with: contentDetails, user: user))
  }
  
  private var notProAlert: Alert {
    return Alert(
      title: Text("PRO Course!"),
      message: Text("You're not a PRO subscriber."),
      dismissButton:
        .default(Text("OK"), action: {
          self.showingProSheet.toggle()
        })
    )
  }
}


