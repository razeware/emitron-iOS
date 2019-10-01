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
  
  @ObservedObject var contentSummaryMC: ContentSummaryMC
  var content: ContentSummaryModel
  var callback: ((ContentDetailsModel)->())?
  var user: UserModel
  
  // These should be private
  @State var isPresented = false
  @State var uiImage: UIImage = #imageLiteral(resourceName: "loading")
  @State var firstLoad: Bool = true

  var imageRatio: CGFloat = 283/375
  
  init(content: ContentSummaryModel, videoID: Int, callback: ((ContentDetailsModel)->())?, user: UserModel) {
    self.content = content
    self.callback = callback
    self.user = user
    self.contentSummaryMC = ContentSummaryMC(guardpost: Guardpost.current, partialContentDetail: content)
  }
  
  private func episodeListing(data: [ContentSummaryModel]) -> some View {
    ForEach(data, id: \.id) { model in
      TextListItemView(contentSummary: model, buttonAction: {
        // Download
      })
      .onTapGesture {
        self.isPresented = true
      }
      .sheet(isPresented: self.$isPresented) { VideoView(contentID: model.id,
                                                         videoID: model.videoID,
                                                         user: self.user) }
    }
  }
  
  var playButton: some View {
    let contentID = self.contentSummaryMC.data.childContents.first?.id ?? 4919757
    return Button(action: {
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
                                                         videoID: self.contentSummaryMC.data.videoID ?? 0,
                                                         user: self.user) }
    }
  }
  
  var coursesSection: AnyView? {
    let groups = contentSummaryMC.data.groups
    
    guard contentSummaryMC.data.contentType == .collection, !groups.isEmpty else {
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
          ZStack {
            Image(uiImage: self.uiImage)
              .resizable()
              .frame(width: geometry.size.width, height: geometry.size.width * self.imageRatio)
              .transition(.opacity)
            Rectangle()
              .foregroundColor(.appBlack)
              .opacity(0.2)
            self.playButton
          }

          ContentSummaryView(callback: self.callback, details: self.contentSummaryMC.data)
            .padding(20)
        }
        .listRowInsets(EdgeInsets())
        
        self.courseDetailsSection()
      }
      .background(Color.paleGrey)
    }
    .onAppear {
      self.loadImage()
      self.contentSummaryMC.getContentSummary()
    }
        
    return scrollView
  }
  
  func courseDetailsSection() -> AnyView {
    switch contentSummaryMC.state {
    case .failed:
      return AnyView(Text("We have failed"))
    case .hasData:
      return AnyView(coursesSection)
    case .initial, .loading:
      return AnyView(Text("Loading"))
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
}
