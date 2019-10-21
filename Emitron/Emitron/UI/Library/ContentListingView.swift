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

struct ContentListingView: View {

  @State private var isEpisodeOnly = false
  @State private var showingSheet = false
  @State var showAlert: Bool = false
  @State var showHudView: Bool = false
  @State var hudOption: HudOption = .success
  @ObservedObject var contentSummaryMC: ContentSummaryMC
  @ObservedObject var downloadsMC: DownloadsMC
  @EnvironmentObject var contentsMC: ContentsMC
  var content: ContentDetailsModel
  var user: UserModel

  // These should be private
  @State var isPresented = false
  @State var uiImage: UIImage = #imageLiteral(resourceName: "loading")

  var imageRatio: CGFloat = 283/375

  init(content: ContentDetailsModel, user: UserModel, downloadsMC: DownloadsMC) {
    self.content = content
    self.user = user
    self.contentSummaryMC = ContentSummaryMC(guardpost: Guardpost.current, partialContentDetail: content)
    self.downloadsMC = downloadsMC
  }

  var body: some View {

    let scrollView = GeometryReader { geometry in
      List {
        Section {

          if self.contentSummaryMC.data.professional && !Guardpost.current.currentUser!.isPro {
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
            }

            self.hudOption = hudOption
          }, downloadsMC: self.downloadsMC, contentSummaryMC: self.contentSummaryMC)
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 37)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)

        self.courseDetailsSection
      }
    }
    .onAppear {
      self.loadImage()
    }
    .navigationBarItems(trailing:
      Group {
        Button(action: {
          self.refreshContentDetails()
        }) {
          Image(systemName: "arrow.clockwise")
            .foregroundColor(.iconButton)
        }
    })
      .hud(isShowing: $showHudView, hudOption: $hudOption) {
        self.showHudView = false
    }
    .actionSheet(isPresented: $showingSheet) {
      actionSheet
    }
    .actionSheet(isPresented: self.$showAlert) {
        ActionSheet(
          title: Text("You are not connected to Wi-Fi"),
          message: Text("Turn on Wi-Fi to access data."),
          buttons: [
            .default(Text("Settings"), action: {
              self.openSettings()
            }),
            .default(Text("OK"), action: {
              self.showAlert.toggle()
            })
          ]
        )
      }

    return scrollView
      .navigationBarTitle(Text(content.name), displayMode: .inline)
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
    if contentSummaryMC.data.videoID != nil {
      return [contentSummaryMC.data]
    }

    let allContents = contentSummaryMC.data.groups.flatMap { $0.childContents }

    guard let currentIndex = allContents.firstIndex(where: { $0.videoID == currentVideoID } )
      else { return [] }

    return allContents[currentIndex..<allContents.count].compactMap { $0 }
  }

  private func episodeListing(data: [ContentDetailsModel]) -> some View {
    let onlyContentWithVideoID = data.filter { $0.videoID != nil }

    return ForEach(onlyContentWithVideoID, id: \.id) { model in

      NavigationLink(destination:
        VideoView(contentDetails: self.contentsToPlay(currentVideoID: model.videoID!),
                  user: self.user,
                  onDisappear: {
                    self.refreshContentDetails()
        })

      ) {

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
        }, downloadsMC: self.downloadsMC, progressionsMC: ProgressionsMC(guardpost: Guardpost.current))

          .onTapGesture {
            self.isPresented = true
        }
      }
        //HACK: to remove navigation chevrons
        .padding(.trailing, -32.0)
    }
    .listRowBackground(Color.backgroundColor)
  }

  private var contentModelForPlayButton: ContentDetailsModel? {
    // If the content is an episode, rather than a collection, it will have a videoID associated with it,
    // so return the content itself
    if contentSummaryMC.data.contentType != .collection {
      return contentSummaryMC.data
    }

    guard let progression = contentSummaryMC.data.progression else {
      return contentSummaryMC.data.groups.first?.childContents.first ?? nil
    }

    // If progressiong is at 100% or 0%, then start from beginning; first child content's video ID
    if progression.finished || progression.percentComplete == 0.0 {
      return contentSummaryMC.data.groups.first?.childContents.first ?? nil
    }

      // If the progression is more than 0%, start at the last consecutive video in a row that hasn't been completed
      // This means that we return true for when the first progression is nil, or when the target > the progress

    else {
      let allContentModels = contentSummaryMC.data.groups.flatMap { $0.childContents }
      let firstUnplayedConsecutive = allContentModels.first { model -> Bool in
        guard let progression = model.progression else { return true }
        return progression.target > progression.progress
      }

      return firstUnplayedConsecutive ?? nil
    }
  }

  private var contentIdForPlayButton: Int {
    return contentModelForPlayButton?.id ?? 0
  }

  private var videoIdForPlayButton: Int {
    return contentModelForPlayButton?.videoID ?? 0
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
          .cornerRadius(11)
        Rectangle()
          .frame(width: 145, height: 65)
          .foregroundColor(.appBlack)
          .cornerRadius(9)

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
          .cornerRadius(11)
        Rectangle()
          .frame(maxWidth: 65, maxHeight: 65)
          .foregroundColor(.appBlack)
          .cornerRadius(9)
        Image("materialIconPlay")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.white)
      }
    }
  }

  var coursesSection: AnyView? {
    let groups = contentSummaryMC.data.groups

    guard contentSummaryMC.data.contentType == .collection else {
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
          // If progress is between 0.0 and 1.0 show continue, otherwise show play
          if self.content.progress > 0.0 && self.content.progress < 1.0 {
            self.continueButton
            //HACK: to center the button when it's in a NavigationLink
              .padding(.leading, geometry.size.width/2 - 74.5)
          } else {
            self.playButton
            //HACK: to center the button when it's in a NavigationLink
            .padding(.leading, geometry.size.width/2 - 32.0)
          }
        }
          //HACK: to remove navigation chevrons
          .padding(.trailing, -32.0)
      }
    }
  }

  private func blurOverlay(for width: CGFloat) -> some View {
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
  }

  private var actionSheet: ActionSheet {
    return showActionSheet(for: .cancel) { action in
      if let action = action, action == .cancel, let content = self.downloadsMC.downloadedContent {
        self.downloadsMC.cancelDownload(with: content, isEpisodeOnly: self.isEpisodeOnly)
        self.showingSheet = false
//        self.showHudView = false
      }
    }
  }

  private var proView: some View {
    return
      VStack {
        HStack {
          Image("padlock")
            .foregroundColor(.white)
          Text("Pro Course")
            .font(.uiTitle1)
            .foregroundColor(.white)
        }

        Text("To unlock this course visit\nraywenderlich.com/subscription\nfor more information")
          .multilineTextAlignment(.center)
          .font(.uiLabelBold)
          .foregroundColor(.white)
          .lineLimit(3)
    }
  }

  //TODO: Honestly, this is probably not the right way to manage the data flow, because the view creating has
  // side effects, but can't think of a cleaner way, other than callbacks...
  private var courseDetailsSection: AnyView {

    switch contentSummaryMC.state {
    case .failed:
      return AnyView(reloadView)
    case .hasData:
      return AnyView(coursesSection)
    case .loading:
      if !contentSummaryMC.data.needsDetails {
        return AnyView(coursesSection)
      } else {
        return AnyView(loadingView)
      }
    case .initial:
      if contentSummaryMC.data.needsDetails {
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
  }

  private var reloadView: AnyView? {
    AnyView(MainButtonView(title: "Reload", type: .primary(withArrow: false)) {
      self.contentSummaryMC.getContentSummary()
    })
  }

  private func loadImage() {
    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
    // is causing this file to not compile

    guard let url = contentSummaryMC.data.cardArtworkURL else {
      return
    }

    DispatchQueue.global().async {
      let data = try? Data(contentsOf: url)
      DispatchQueue.main.async {
        if let data = data,
          let img = UIImage(data: data) {
          self.uiImage = img
        }
      }
    }
  }

  private func refreshContentDetails() {
    self.contentSummaryMC.getContentSummary { model in
      // Update the content in the global contentsMC, to keep all the data in sync
      guard let index = self.contentsMC.data.firstIndex(where: { model.id == $0.id } ) else { return }
      self.contentsMC.updateEntry(at: index, with: model)
    }
  }

  private func save(for content: ContentDetailsModel, isEpisodeOnly: Bool) {
    // update bool so can cancel either entire collection or episode based on bool
    self.isEpisodeOnly = isEpisodeOnly
    downloadsMC.isEpisodeOnly = isEpisodeOnly
    guard !downloadsMC.data.contains(where: { $0.content.id == content.id }) else {
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
