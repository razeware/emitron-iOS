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
  var childContentsViewModel: ChildContentsViewModel
  var dynamicContentViewModel: DynamicContentViewModel

  @EnvironmentObject var sessionController: SessionController
  var user: User {
    sessionController.user!
  }
  
  private var canStreamPro: Bool {
    return user.canStreamPro
  }
  
  var imageRatio: CGFloat = 283/375
  
  
  var body: some View {
    contentView
  }
  
  var contentView: some View {
    let scrollView = GeometryReader { geometry in
      List {
        Section {
          
          if self.content.professional && !self.canStreamPro {
            self.blurOverlay(for: geometry.size.width)
          } else {
            self.opacityOverlay(for: geometry.size.width)
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
  
  
  private var continueButton: some View {
    let viewModel = dynamicContentViewModel.videoPlaybackViewModel(apiClient: sessionController.client)
    return NavigationLink(destination: VideoView(viewModel: viewModel)) {
      ZStack {
        Rectangle()
          .frame(width: 155, height: 75)
          .foregroundColor(.white)
          .cornerRadius(13)
        Rectangle()
          .frame(width: 145, height: 65)
          .foregroundColor(.appBlack)
          .cornerRadius(11)
        
        HStack {
          Image("materialIconPlay")
            .resizable()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
          Text("Continue")
            .foregroundColor(.white)
            .font(.uiLabelBold)
        }
          //HACK: Beacuse the play button has padding on it
          .padding([.leading], -7)
      }
    }
  }
  
  private var playButton: some View {
    let viewModel = dynamicContentViewModel.videoPlaybackViewModel(apiClient: sessionController.client)
    return NavigationLink(destination: VideoView(viewModel: viewModel)) {
      ZStack {
        Rectangle()
          .frame(maxWidth: 75, maxHeight: 75)
          .foregroundColor(.white)
          .cornerRadius(13)
        Rectangle()
          .frame(maxWidth: 65, maxHeight: 65)
          .foregroundColor(.appBlack)
          .cornerRadius(11)
        Image("materialIconPlay")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.white)
      }
    }
  }

  private func opacityOverlay(for width: CGFloat) -> some View {
    VStack(spacing: 0, content: {
      ZStack(alignment: .center) {
        KFImage(content.cardArtworkUrl)
          .resizable()
          .frame(width: width, height: width * imageRatio)
          .transition(.opacity)
        
        Rectangle()
          .foregroundColor(.appBlack)
          .opacity(0.2)
        
        GeometryReader { geometry in
          HStack {
            self.continueOrPlayButton(geometry: geometry)
          }
            //HACK: to remove navigation chevrons
            .padding(.trailing, -32.0)
        }
      }
      progressBar
    })
  }
  
  private func blurOverlay(for width: CGFloat) -> some View {
    VStack {
      ZStack {
        KFImage(content.cardArtworkUrl)
          .resizable()
          .frame(width: width, height: width * imageRatio)
          .transition(.opacity)
          .blur(radius: 10)
        
        Rectangle()
          .foregroundColor(.appBlack)
          .opacity(0.5)
          .blur(radius: 10)
        
        proView
      }
      progressBar
    }
  }
  
  private func continueOrPlayButton(geometry: GeometryProxy) -> AnyView {
    if case .inProgress = dynamicContentViewModel.viewProgress {
      return AnyView(self.continueButton
        //HACK: to center the button when it's in a NavigationLink
        .padding(.leading, geometry.size.width/2 - 74.5))
    } else {
      return AnyView(self.playButton
        //HACK: to center the button when it's in a NavigationLink
        .padding(.leading, geometry.size.width/2 - 32.0))
    }
  }
  
  private var progressBar: AnyView? {
    if case .inProgress(let progress) = dynamicContentViewModel.viewProgress {
      return AnyView(ProgressBarView(progress: progress, isRounded: false))
    }
    return nil
  }
  
  private var proView: some View {
    return
      VStack {
        HStack {
          Image("padlock")
          
          Text("Pro Course")
            .font(.uiTitle1)
            .foregroundColor(.white)
        }
        
        Text("To unlock this course visit raywenderlich.com/subscription for more information")
          .multilineTextAlignment(.center)
          .font(.uiLabel)
          .foregroundColor(.white)
          .padding([.leading, .trailing], 20)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
    }
  }
  
  private func refreshContentDetails() {
    dynamicContentViewModel.reload()
    childContentsViewModel.reload()
  }
  
  private func save(for contentId: Int) {
    // TODO
  }
    
}
