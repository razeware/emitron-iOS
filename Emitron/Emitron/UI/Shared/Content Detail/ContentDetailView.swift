// Copyright (c) 2019 Razeware LLC
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

struct ContentDetailView {
  init(
    content: ContentListDisplayable,
    childContentsViewModel: ChildContentsViewModel,
    dynamicContentViewModel: DynamicContentViewModel
  ) {
    self.content = content
    self.childContentsViewModel = childContentsViewModel
    self.dynamicContentViewModel = dynamicContentViewModel
  }

  private let content: ContentListDisplayable
  @ObservedObject private var childContentsViewModel: ChildContentsViewModel
  @ObservedObject private var dynamicContentViewModel: DynamicContentViewModel

  @EnvironmentObject private var sessionController: SessionController

  @State private var currentlyDisplayedVideoPlaybackViewModel: VideoPlaybackViewModel?
}

// MARK: - View
extension ContentDetailView: View {
  var body: some View {
    ZStack {
      contentView
      
      if currentlyDisplayedVideoPlaybackViewModel != nil {
        FullScreenVideoPlayerRepresentable(viewModel: $currentlyDisplayedVideoPlaybackViewModel)
      }
    }
  }
}

// MARK: - private
private extension ContentDetailView {
  var contentView: some View {
    GeometryReader { geometry in
      List {
        Section {
          if content.professional && !canStreamPro {
            headerImageLockedProContent(for: geometry.size.width)
          } else {
            headerImagePlayableContent(for: geometry.size.width)
          }
          
          ContentSummaryView(content: content, dynamicContentViewModel: dynamicContentViewModel)
            .padding([.leading, .trailing], 20)
            .padding(.bottom, 37)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
        
        ChildContentListingView(
          childContentsViewModel: childContentsViewModel,
          currentlyDisplayedVideoPlaybackViewModel: $currentlyDisplayedVideoPlaybackViewModel
        )
          .background(Color.backgroundColor)
      }
    }
      .navigationBarTitle(Text(""), displayMode: .inline)
      .background(Color.backgroundColor)
  }

  var canStreamPro: Bool { user.canStreamPro }
  var user: User { sessionController.user! }

  var imageRatio: CGFloat { 283 / 375 }
  var maxImageHeight: CGFloat { 384 }

  func openSettings() {
    // open iPhone settings
    if
      let url = URL(string: UIApplication.openSettingsURLString),
      UIApplication.shared.canOpenURL(url)
    { UIApplication.shared.open(url) }
  }
  
  var continueOrPlayButton: some View {
    Button(action: {
      currentlyDisplayedVideoPlaybackViewModel = dynamicContentViewModel.videoPlaybackViewModel(
        apiClient: sessionController.client,
        dismissClosure: {
          currentlyDisplayedVideoPlaybackViewModel = nil
        }
      )
    }) {
      if case .hasData = childContentsViewModel.state {
        if case .inProgress = dynamicContentViewModel.viewProgress {
          ContinueButtonView()
        } else {
          PlayButtonView()
        }
      } else {
        HStack {
          Spacer()
          ActivityIndicator()
          Spacer()
        }
      }
    }
  }

  func headerImagePlayableContent(for width: CGFloat) -> some View {
    VStack(spacing: 0, content: {
      ZStack(alignment: .center) {
        VerticalFadeImageView(
          imageURL: content.cardArtworkURL,
          blurred: false,
          width: width,
          height: min(width * imageRatio, maxImageHeight)
        )
        
        continueOrPlayButton
      }
      
      progressBar
    })
  }
  
  func headerImageLockedProContent(for width: CGFloat) -> some View {
    ZStack {
      VerticalFadeImageView(
        imageURL: content.cardArtworkURL,
        blurred: true,
        width: width,
        height: min(width * imageRatio, maxImageHeight)
      )
      
      ProContentLockedOverlayView()
    }
  }
  
  var progressBar: ProgressBarView? {
    guard case .inProgress(let progress) = dynamicContentViewModel.viewProgress
    else { return nil }

    return .init(progress: progress, isRounded: false)
  }
}
