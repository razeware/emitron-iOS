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
  @State private var checkReviewRequest = false
  @ObservedObject private var childContentsViewModel: ChildContentsViewModel
  @ObservedObject private var dynamicContentViewModel: DynamicContentViewModel

  @EnvironmentObject private var sessionController: SessionController
  @EnvironmentObject private var messageBus: MessageBus
  @Environment(\.mainTab) private var mainTab

  @State private var currentlyDisplayedVideoPlaybackViewModel: VideoPlaybackViewModel?
  private let videoCompletedNotification = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
}

// MARK: - View
extension ContentDetailView: View {
  var body: some View {
    ZStack {
      contentView

      if let model = currentlyDisplayedVideoPlaybackViewModel {
        try? FullScreenVideoPlayer(
          model: model,
          messageBus: messageBus,
          handleDismissal: {
            currentlyDisplayedVideoPlaybackViewModel = nil
          }
        )
      }
    }
  }
}

// MARK: - private
private extension ContentDetailView {
  var contentView: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack {
          headerImage(width: geometry.size.width)
            .id(TabViewModel.ScrollToTopID(mainTab: mainTab, detail: true))
          
          ContentSummaryView(content: content, dynamicContentViewModel: dynamicContentViewModel)
            .padding(.horizontal, 20)
            .background(Color.background)
          
          ChildContentListingView(
            childContentsViewModel: childContentsViewModel,
            currentlyDisplayedVideoPlaybackViewModel: $currentlyDisplayedVideoPlaybackViewModel
          )
          .background(Color.background)
        }
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .background(Color.background)
    .onReceive(videoCompletedNotification) { _ in
      checkReviewRequest = true
    }
    .onAppear {
      guard
        checkReviewRequest,
        case .completed = dynamicContentViewModel.viewProgress,
        let lastPrompted = NSUbiquitousKeyValueStore.default.object(forKey: LookupKey.requestReview) as? TimeInterval,
        isPastTwoWeeks(.now, from: .init(timeIntervalSince1970: lastPrompted))
      else { return }

      NotificationCenter.default.post(name: .requestReview, object: nil)
      NSUbiquitousKeyValueStore.default.set(Date.now.timeIntervalSince1970, forKey: LookupKey.requestReview)
    }
  }

  var canStreamPro: Bool { user.canStreamPro }
  var user: User { sessionController.user! }

  var imageRatio: CGFloat { 283 / 375 }
  var maxImageHeight: CGFloat { 384 }
  
  var continueOrPlayButton: some View {
    Button {
      currentlyDisplayedVideoPlaybackViewModel = dynamicContentViewModel.videoPlaybackViewModel(
        apiClient: sessionController.client,
        dismissClosure: {
          currentlyDisplayedVideoPlaybackViewModel = nil
        }
      )
    } label: {
      if case .hasData = childContentsViewModel.state {
        if case .inProgress = dynamicContentViewModel.viewProgress {
          ContinueButtonView()
        } else {
          PlayButtonView()
        }
      } else {
        HStack {
          Spacer()
          ProgressView().scaleEffect(1, anchor: .center)
          Spacer()
        }
      }
    }
  }

  @ViewBuilder func headerImage(width: Double) -> some View {
    if content.professional && !canStreamPro {
      headerImageLockedProContent(for: width)
    } else {
      headerImagePlayableContent(for: width)
    }
  }

  func headerImagePlayableContent(for width: Double) -> some View {
    VStack(spacing: 0) {
      ZStack(alignment: .center) {
        VerticalFadeImageView(
          imageURL: content.cardArtworkURL,
          blurred: false,
          width: width,
          height: min(width * imageRatio, maxImageHeight)
        )
        
        continueOrPlayButton
      }
      
      if case .inProgress(let progress) = dynamicContentViewModel.viewProgress {
        ProgressBarView(progress: progress, isRounded: false)
      }
    }
  }
  
  func headerImageLockedProContent(for width: Double) -> some View {
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

  func isPastTwoWeeks(_ currentWeek: Date, from lastWeek: Date) -> Bool {
    Calendar.current.dateComponents([.weekOfYear], from: lastWeek, to: currentWeek)
      .weekOfYear.map { $0 >= 2 } == true
  }
}
