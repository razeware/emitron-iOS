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
import KingfisherSwiftUI
import UIKit

struct ContentDetailView: View {
  var content: ContentListDisplayable
  @ObservedObject var childContentsViewModel: ChildContentsViewModel
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel

  @EnvironmentObject var sessionController: SessionController
  var user: User {
    sessionController.user!
  }
  
  private var canStreamPro: Bool {
    user.canStreamPro
  }
  
  var imageRatio: CGFloat = 283 / 375
  
  var body: some View {
    contentView
  }
  
  var contentView: some View {
    let scrollView = GeometryReader { geometry in
      List {
        Section {
          
          if self.content.professional && !self.canStreamPro {
            self.headerImageLockedProContent(for: geometry.size.width)
          } else {
            self.headerImagePlayableContent(for: geometry.size.width)
          }
          
          ContentSummaryView(content: self.content, dynamicContentViewModel: self.dynamicContentViewModel)
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 37)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
        
        ChildContentListingView(childContentsViewModel: self.childContentsViewModel)
          .background(Color.backgroundColor)
      }
    }
    .navigationBarItems(trailing:
      SwiftUI.Group {
        Button(action: {
          self.refreshContentDetails()
        }) {
          Image(systemName: "arrow.clockwise")
            .foregroundColor(.iconButton)
        }
      })
    
    return scrollView
      .navigationBarTitle(Text(""), displayMode: .inline)
      .background(Color.backgroundColor)
  }
  
  private func openSettings() {
    // open iPhone settings
    if let url = URL(string: UIApplication.openSettingsURLString) {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }
  
  private var continueOrPlayButton: NavigationLink<AnyView, VideoView> {
    let viewModel = dynamicContentViewModel.videoPlaybackViewModel(apiClient: sessionController.client)
    return NavigationLink(destination: VideoView(viewModel: viewModel)) {
      if case .hasData = childContentsViewModel.state {
        if case .inProgress = dynamicContentViewModel.viewProgress {
          return AnyView(ContinueButtonView())
        } else {
          return AnyView(PlayButtonView())
        }
      } else {
        return AnyView(
          HStack {
            Spacer()
            ActivityIndicator()
            Spacer()
          }
        )
      }
    }
  }

  private func headerImagePlayableContent(for width: CGFloat) -> some View {
    VStack(spacing: 0, content: {
      ZStack(alignment: .center) {
        VerticalFadeImageView(imageUrl: content.cardArtworkUrl)
          .frame(width: width, height: width * imageRatio)
        
        continueOrPlayButton
          .padding(.trailing, -32.0) // HACK: to remove navigation chevrons
      }
      
      progressBar
    })
  }
  
  private func headerImageLockedProContent(for width: CGFloat) -> some View {
    ZStack {
      VerticalFadeImageView(imageUrl: content.cardArtworkUrl, blurred: true)
        .frame(width: width, height: width * imageRatio)
      
      ProContentLockedOverlayView()
    }
  }
  
  private var progressBar: AnyView? {
    if case .inProgress(let progress) = dynamicContentViewModel.viewProgress {
      return AnyView(ProgressBarView(progress: progress, isRounded: false))
    }
    return nil
  }
  
  private func refreshContentDetails() {
    dynamicContentViewModel.reload()
    childContentsViewModel.reload()
  }
}
