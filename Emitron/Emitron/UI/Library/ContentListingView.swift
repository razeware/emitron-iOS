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

struct ContentListingView: View {

  @State var showHudView: Bool = false
  @State var hudOption: HudOption = .success
  @ObservedObject var contentSummaryMC: ContentSummaryMC
  var downloadsMC: DownloadsMC
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

  private func episodeListing(data: [ContentDetailsModel]) -> some View {
    let onlyContentWithVideoID = data.filter { $0.videoID != nil }

    return AnyView(ForEach(onlyContentWithVideoID, id: \.id) { model in
      TextListItemView(contentSummary: model, buttonAction: { success in
        if success {
          self.save(for: model)
        } else {
          if self.showHudView {
            self.showHudView.toggle()
          }

          self.hudOption = success ? .success : .error
          self.showHudView = true
        }
      }, downloadsMC: self.downloadsMC)

      .onTapGesture {
        self.isPresented = true
      }
      .sheet(isPresented: self.$isPresented) { VideoView(contentID: model.id,
                                                         videoID: model.videoID!,
                                                         user: self.user) }
    })
  }
  
  private var playButton: AnyView? {
    guard let videoID = contentSummaryMC.data.videoID,
    let contentID = self.contentSummaryMC.data.childContents.first?.id else { return nil }

    return AnyView(Button(action: {
      self.isPresented = true
    }) {

      ZStack {
        Rectangle()
          .frame(maxWidth: 70, maxHeight: 70)
          .foregroundColor(.white)
          .cornerRadius(6)
        Rectangle()
          .frame(maxWidth: 60, maxHeight: 60)
          .foregroundColor(.appBlack)
          .cornerRadius(6)
        Image("materialIconPlay")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.white)

      }
      .sheet(isPresented: self.$isPresented) { VideoView(contentID: contentID,
                                                         videoID: videoID,
                                                         user: self.user) }
    })
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

          Section(header: CourseHeaderView(name: group.name, color: .white)
            .background(Color.white)) {
              self.episodeListing(data: group.childContents)
          }
        }
      } else {
        self.episodeListing(data: groups.first!.childContents)
      }
    }

    return AnyView(sections)
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

          ContentSummaryView(callback: { (content, success) in
            if success {
              self.save(for: content)
            } else {
              if self.showHudView {
                self.showHudView.toggle()
              }

              self.hudOption = success ? .success : .error
              self.showHudView = true
            }
          }, downloadsMC: self.downloadsMC, contentSummaryMC: self.contentSummaryMC)
            .padding(20)
        }
        .listRowInsets(EdgeInsets())

        self.courseDetailsSection
      }
      .background(Color.paleGrey)
    }
    .onAppear {
      self.loadImage()
      self.contentSummaryMC.getContentSummary()
    }
    .hud(isShowing: $showHudView, hudOption: $hudOption) {
      self.showHudView = false
    }

    return scrollView
  }

  private func opacityOverlay(for width: CGFloat) -> some View {
    ZStack {
      Image(uiImage: uiImage)
        .resizable()
        .frame(width: width, height: width * imageRatio)
        .transition(.opacity)

      Rectangle()
        .foregroundColor(.appBlack)
        .opacity(0.2)

      playButton
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
          .font(.uiLabel)
          .foregroundColor(.white)
          .lineLimit(3)
    }
  }

  private var courseDetailsSection: AnyView {
    
    switch contentSummaryMC.state {
    case .failed:
      return AnyView(Text("We have failed"))
    case .hasData:
      return AnyView(coursesSection)
    case .initial, .loading:
      return AnyView(loadingView)
    }
  }

  private var loadingView: some View {
    VStack {
      Spacer()

      Text("Loading...")
        .font(.uiTitle2)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)

      Spacer()
    }
  }

  func loadImage() {
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

  private func save(for content: ContentDetailsModel) {
    guard downloadsMC.state != .loading else {
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = .error
      self.showHudView = true
      return
    }

    guard !downloadsMC.data.contains(where: { $0.content.id == content.id }) else {
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = .error
      self.showHudView = true
      return
    }
    
    if content.videoID == nil {
      self.downloadsMC.saveCollection(with: content)
    } else {
      self.downloadsMC.saveDownload(with: content)
    }
    
    self.downloadsMC.callback = { success in
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = success ? .success : .error
      self.showHudView = true
    }
  }
}
