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
  
  @State private var isEpisodeOnly = false
  @State private var showingSheet = false
  @State var showAlert: Bool = false
  @State var showHudView: Bool = false
  @State var hudOption: HudOption = .success
  @ObservedObject var contentDetailsViewModel: ContentDetailsViewModel
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
  
  var contentView: AnyView {
    switch contentDetailsViewModel.state {
    case .initial:
      contentDetailsViewModel.reload()
      return AnyView(Text("loading..."))
    case .hasData:
      return AnyView(dataLoadedView)
    default:
      return AnyView(Text("loading..."))
    }
  }
    
  var dataLoadedView: some View {
    let scrollView = GeometryReader { geometry in
      List {
        Section {
          
          if (self.contentDetailsViewModel.content?.professional ?? false) && !self.canStreamPro {
            self.blurOverlay(for: geometry.size.width)
          } else {
            self.opacityOverlay(for: geometry.size.width)
          }
          
          ContentSummaryView(callback: { (content, hudOption) in
            switch hudOption {
              case .success:
                self.save(for: content.id)
              case .error:
                if self.showHudView {
                  self.showHudView.toggle()
                }
                self.showHudView = true
              case .notOnWifi:
                self.showAlert = true
                self.showingSheet = true
            }
            
            self.hudOption = hudOption
          }, contentDetailsViewModel: self.contentDetailsViewModel)
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 37)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
        
        self.courseDetailsSection
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
      .actionSheet(isPresented: $showingSheet) {
        actionSheet
    }
    .hud(isShowing: $showHudView, hudOption: $hudOption) {
      self.showHudView = false
    }
    
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
  
  private func contentsToPlay(currentVideoID: Int) -> [ContentListDisplayable] {
    
    // If the content is a single episode, which we know by checking if there's a videoID on it, return the content itself
    guard let content = contentDetailsViewModel.content else { return [] }
    
    if content.videoIdentifier != nil {
      return [content]
    }
    
    let childContents = contentDetailsViewModel.childContents
    
    guard let currentIndex = childContents.firstIndex(where: { $0.videoIdentifier == currentVideoID } )
      else { return [] }
    
    return Array(childContents[currentIndex..<childContents.count])
  }
  
  private func episodeListing(data: [ContentListDisplayable]) -> some View {
    let onlyContentWithVideoID = data.filter { $0.videoIdentifier != nil }
    
    return ForEach(onlyContentWithVideoID, id: \.id) { model in
      
      NavigationLink(destination:
        self.videoView(for: model)
      ) {
        self.rowItem(for: model)
          .padding([.leading, .trailing], 20)
          .padding([.bottom], 20)
      }
        //HACK: to remove navigation chevrons
        .padding(.trailing, -32.0)
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.backgroundColor)
  }
  
  private func rowItem(for model: ContentListDisplayable) -> some View {
    TextListItemView(contentSummary: model, buttonAction: { success in
      if success {
        self.save(for: model.id)
      } else {
        if self.showHudView {
          self.showHudView.toggle()
        }
        
        self.hudOption = success ? .success : .error
        self.showHudView = true
      }
    })
  }
  
  private func videoView(for model: ContentListDisplayable) -> some View {
    VideoView(contentDetails: self.contentsToPlay(currentVideoID: model.videoIdentifier!),
              user: self.user,
              showingProSheet: !self.user.canStreamPro && model.professional) {
                self.refreshContentDetails()
    }
  }
  
  private var contentModelForPlayButton: ContentListDisplayable? {
    guard let content = contentDetailsViewModel.content else { return nil }
    
    // If the content is an episode, rather than a collection, it will have a videoID associated with it,
    // so return the content itself
    if content.contentType != .collection {
      return contentDetailsViewModel.content
    }
    
    // If the progression is more than 0%, start at the last consecutive video in a row that hasn't been completed
    // This means that we return true for when the first progression is nil, or when the target > the progress
    if case .inProgress(let percentage) = content.viewProgress, percentage > 0 {
      return contentDetailsViewModel.childContents.first { childContent in
        if case .completed = childContent.viewProgress {
          return false
        }
        return true
      }
    }
    
    // If progression is at 100% or 0%, then start from beginning; first child content's video ID
    return contentDetailsViewModel.childContents.first
  }
  
  private var contentIdForPlayButton: Int {
    return contentModelForPlayButton?.id ?? 0
  }
  
  private var videoIdForPlayButton: Int {
    return contentModelForPlayButton?.videoIdentifier ?? 0
  }
  
  private var continueButton: some View {
    return NavigationLink(destination:
      VideoView(contentDetails: self.contentsToPlay(currentVideoID: self.videoIdForPlayButton),
                user: self.user))
    {
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
    
    return NavigationLink(destination:
      VideoView(contentDetails: self.contentsToPlay(currentVideoID: self.videoIdForPlayButton),
                user: self.user))
    {
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
  
  var coursesSection: AnyView? {
    guard let content = contentDetailsViewModel.content,
      content.contentType == .collection else { return nil }
    
    let childContents = contentDetailsViewModel.childContents
    let groups = content.groups
    let sections = Section {
      Text("Course Episodes")
        .font(.uiTitle2)
        .padding([.top], -5)
      
      if groups.count > 1 {
        ForEach(groups, id: \.id) { group in
          
          Section(header: CourseHeaderView(name: group.name)) {
            self.episodeListing(data: childContents.filter { $0.groupId == group.id })
          }
        }
      } else {
        if groups.count > 0 {
          self.episodeListing(data: childContents.filter { $0.groupId == groups.first!.id })
        }
      }
    }
    .listRowBackground(Color.backgroundColor)
    
    return AnyView(sections)
  }
  
  private func opacityOverlay(for width: CGFloat) -> some View {
    VStack(spacing: 0, content: {
      ZStack(alignment: .center) {
        KFImage(contentDetailsViewModel.content!.cardArtworkUrl)
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
        KFImage(contentDetailsViewModel.content!.cardArtworkUrl)
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
    if case .inProgress = self.contentDetailsViewModel.content!.viewProgress {
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
    if case .inProgress(let progress) = self.contentDetailsViewModel.content!.viewProgress {
      return AnyView(ProgressBarView(progress: progress, isRounded: false))
    }
    return nil
  }
  
  private var wifiActionSheet: ActionSheet {
    return ActionSheet(
      title: Text("You are not connected to Wi-Fi"),
      message: Text("Turn on Wi-Fi to access data."),
      buttons: [
        .default(Text("Settings"), action: {
          self.openSettings()
        }),
        .default(Text("OK"), action: {
          self.showAlert.toggle()
          self.showingSheet.toggle()
        })
      ]
    )
  }
  
  private var actionSheet: ActionSheet {
    if showAlert {
      return wifiActionSheet
    } else {
      return showActionSheet(for: .cancel) { action in
//        if let action = action, action == .cancel, let content = self.downloadsMC.downloadedContent {
//          self.downloadsMC.cancelDownload(with: content, isEpisodeOnly: self.isEpisodeOnly)
//          self.showingSheet = false
//          self.showHudView = false
//        }
      }
    }
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
  
  //TODO: Honestly, this is probably not the right way to manage the data flow, because the view creating has
  // side effects, but can't think of a cleaner way, other than callbacks...
  private var courseDetailsSection: AnyView {
    
    switch contentDetailsViewModel.state {
      case .failed:
        return AnyView(reloadView)
      case .hasData:
        return AnyView(coursesSection)
    case .loading, .loadingAdditional, .initial:
        return AnyView(loadingView)
    }
  }
  
  private var loadingView: some View {
    // HACK: To put it in the middle we have to wrap it in Geometry Reader
    GeometryReader { geometry in
      ActivityIndicator()
    }
    .listRowInsets(EdgeInsets())
    .listRowBackground(Color.backgroundColor)
    .background(Color.backgroundColor)
  }
  
  private var reloadView: AnyView? {
    AnyView(MainButtonView(title: "Reload", type: .primary(withArrow: false)) {
      self.contentDetailsViewModel.reload()
    })
  }
  
  private func refreshContentDetails() {
    self.contentDetailsViewModel.reload()
  }
  
  private func save(for contentId: Int) {
    // TODO
  }
    
}
