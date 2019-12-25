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
import UIKit

struct ContentDetailView: View {
  
  @State private var isEpisodeOnly = false
  @State private var showingSheet = false
  @State var showAlert: Bool = false
  @State var showHudView: Bool = false
  @State var hudOption: HudOption = .success
  @ObservedObject var contentDetailsVM: ContentDetailsVM
  @ObservedObject var downloadsMC: DownloadsMC
  var content: ContentListDisplayable
  var user: UserModel
  @State var imageData: Data?
  
  private var canStreamPro: Bool {
    return user.canStreamPro
  }
  
  // These should be private
  @State var uiImage: UIImage = #imageLiteral(resourceName: "loading")
  
  var imageRatio: CGFloat = 283/375
  
  init(content: ContentListDisplayable, user: UserModel, downloadsMC: DownloadsMC) {
    self.content = content
    self.user = user
    self.contentDetailsVM = ContentDetailsVM(guardpost: Guardpost.current, partialContentDetail: content)
    self.downloadsMC = downloadsMC
  }
  
  var body: some View {
    
    let scrollView = GeometryReader { geometry in
      List {
        Section {
          
          if self.contentDetailsVM.data.professional && !self.canStreamPro {
            self.blurOverlay(for: geometry.size.width)
          } else {
            self.opacityOverlay(for: geometry.size.width)
          }
          
          ContentSummaryView(callback: { (content, hudOption) in
            switch hudOption {
              case .success:
                self.save(for: content, isEpisodeOnly: false)
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
          }, downloadsMC: self.downloadsMC, contentDetailsVM: self.contentDetailsVM)
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 37)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
        
        self.courseDetailsSection
          .background(Color.backgroundColor)
      }
    }
    .onAppear {
      self.loadImage()
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
  
  private func contentsToPlay(currentVideoID: Int) -> [ContentDetailsModel] {
    
    // If the content is a single episode, which we know by checking if there's a videoID on it, return the content itself
    if contentDetailsVM.data.videoId != nil {
      return [contentDetailsVM.data]
    }
    
    let allContents = contentDetailsVM.data.groups.flatMap { $0.childContents }
    
    guard let currentIndex = allContents.firstIndex(where: { $0.videoId == currentVideoID } )
      else { return [] }
    
    return allContents[currentIndex..<allContents.count].compactMap { $0 }
  }
  
  private func episodeListing(data: [ContentDetailsModel]) -> some View {
    let onlyContentWithVideoID = data.filter { $0.videoId != nil }
    
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
  
  private func rowItem(for model: ContentDetailsModel) -> some View {
    TextListItemView(contentSummary: model, buttonAction: { success in
      if success {
        self.save(for: model, isEpisodeOnly: true)
      } else {
        if self.showHudView {
          self.showHudView.toggle()
        }
        
        self.hudOption = success ? .success : .error
        self.showHudView = true
      }
    }, downloadsMC: self.downloadsMC, progressionsMC: ProgressionsMC(user: Guardpost.current.currentUser!))
  }
  
  private func videoView(for model: ContentDetailsModel) -> some View {
    VideoView(contentDetails: self.contentsToPlay(currentVideoID: model.videoId!),
              user: self.user,
              showingProSheet: !self.user.canStreamPro && model.professional) {
                self.refreshContentDetails()
    }
  }
  
  private var contentModelForPlayButton: ContentDetailsModel? {
    // If the content is an episode, rather than a collection, it will have a videoID associated with it,
    // so return the content itself
    if contentDetailsVM.data.contentType != .collection {
      return contentDetailsVM.data
    }
    
    guard let progression = contentDetailsVM.data.progression else {
      return contentDetailsVM.data.groups.first?.childContents.first ?? nil
    }
    
    // If progressiong is at 100% or 0%, then start from beginning; first child content's video ID
    if progression.finished || progression.percentComplete == 0.0 {
      return contentDetailsVM.data.groups.first?.childContents.first ?? nil
    }
      
      // If the progression is more than 0%, start at the last consecutive video in a row that hasn't been completed
      // This means that we return true for when the first progression is nil, or when the target > the progress
      
    else {
      let allContentModels = contentDetailsVM.data.groups.flatMap { $0.childContents }
      let firstUnplayedConsecutive = allContentModels.first { model -> Bool in
        guard let progression = model.progression else { return true }
        return progression.target > progression.progress && !progression.finished
      }
      
      return firstUnplayedConsecutive ?? nil
    }
  }
  
  private var contentIdForPlayButton: Int {
    return contentModelForPlayButton?.id ?? 0
  }
  
  private var videoIdForPlayButton: Int {
    return contentModelForPlayButton?.videoId ?? 0
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
    let groups = contentDetailsVM.data.groups
    
    guard contentDetailsVM.data.contentType == .collection else {
      return nil
    }
    
    let sections = Section {
      Text("Course Episodes")
        .font(.uiTitle2)
        .padding([.top], -5)
      
      if groups.count > 1 {
        ForEach(groups, id: \.id) { group in
          
          Section(header: CourseHeaderView(name: group.name)) {
            self.episodeListing(data: group.childContents)
          }
        }
      } else {
        if groups.count > 0 {
          self.episodeListing(data: groups.first!.childContents)
        }
      }
    }
    .listRowBackground(Color.backgroundColor)
    
    return AnyView(sections)
  }
  
  private func opacityOverlay(for width: CGFloat) -> some View {
    VStack(spacing: 0, content: {
      ZStack(alignment: .center) {
        Image(uiImage: uiImage)
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
        Image(uiImage: uiImage)
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
    if case .inProgress = self.content.progress {
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
    guard let progression = content.progression, !progression.finished else { return nil }
    return AnyView(ProgressBarView(progress: content.progress, isRounded: false))
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
        if let action = action, action == .cancel, let content = self.downloadsMC.downloadedContent {
          self.downloadsMC.cancelDownload(with: content, isEpisodeOnly: self.isEpisodeOnly)
          self.showingSheet = false
          self.showHudView = false
        }
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
    
    switch contentDetailsVM.state {
      case .failed:
        return AnyView(reloadView)
      case .hasData:
        return AnyView(coursesSection)
      case .loading:
        if !contentDetailsVM.data.needsDetails {
          return AnyView(coursesSection)
        } else {
          return AnyView(loadingView)
      }
      case .initial:
        if contentDetailsVM.data.needsDetails {
          refreshContentDetails()
        }
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
      self.contentDetailsVM.getContentSummary()
    })
  }
  
  private func loadImage() {
    
    // first check if image data has already been saved
    if let data = contentDetailsVM.data.cardArtworkData,
      let uiImage = UIImage(data: data) {
      self.uiImage = uiImage
      
      // otherwise use the imageURL
    } else {
      let imageURL = contentDetailsVM.data.cardArtworkUrl
      DispatchQueue.global().async {
        let data = try? Data(contentsOf: imageURL)
        DispatchQueue.main.async {
          if let data = data, let img = UIImage(data: data) {
            self.uiImage = img
            self.imageData = data
          }
        }
      }
    }
  }
  
  private func refreshContentDetails() {
    self.contentDetailsVM.getContentSummary { model in
      // Update the content in the global contentsMC, to keep all the data in sync
      guard let dataManager = DataManager.current else { return }
      dataManager.disseminateUpdates(for: model)
    }
  }
  
  private func save(for content: ContentDetailsModel, isEpisodeOnly: Bool) {
    // update content to save with image data
    content.cardArtworkData = imageData
    
    // update bool so can cancel either entire collection or episode based on bool
    self.isEpisodeOnly = isEpisodeOnly
    downloadsMC.isEpisodeOnly = isEpisodeOnly
    guard !downloadsMC.data.contains(where: { $0.id == content.id }) else {
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }
      
      self.hudOption = .error
      self.showHudView = true
      return
    }
    
    // show sheet to cancel download
    self.showingSheet = true
    
    if isEpisodeOnly {
      self.downloadsMC.saveDownload(with: content, isEpisodeOnly: isEpisodeOnly)
    } else if content.isInCollection {
      self.downloadsMC.saveCollection(with: content, isEpisodeOnly: false)
    } else {
      self.downloadsMC.saveDownload(with: content, isEpisodeOnly: false)
    }
    
    self.downloadsMC.callback = { success in
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }
      
      self.hudOption = success ? .success : .error
      self.showHudView = true
      // hide sheet to cancel
      self.showingSheet = false
    }
  }
}