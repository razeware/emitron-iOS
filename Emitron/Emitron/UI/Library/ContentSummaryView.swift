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

struct ContentSummaryView: View {
  
  @ObjectBinding var contentDetailsMC: ContentDetailsMC
  @State var isPresented = false
  
  var video: Video?
  
  var body: some View {
    
    //TODO: Loading workaround til I find something better
    if contentDetailsMC.data.groups.isEmpty {
      fetchList()
    }
    
    return VStack {
      
      mainView()
      
      //TODO: Loading workaround til I find something better
      if !contentDetailsMC.data.groups.isEmpty {
        buildList()
        .padding([.leading], 5)
      }
    }
      .background(Color.paleGrey)
  }
  
  func mainView() -> AnyView {
    // IMAGE: Background blurred photo
    
    // ISSUE: Embedding into a scrollview seems to get rid of multiline text
    // .frame(.infinity) seems like a hack
    return AnyView(ScrollView(.vertical, showsIndicators: false) {
      VStack {
        Button("PLAY") {
          self.playVideo()
        }
        .frame(minHeight: 285)
        
        VStack(alignment: .leading) {
          TopSummaryView(details: contentDetailsMC.data)
          
          // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
          Text("Courses") // TITLE
            .font(.uiTitle2)
            .lineLimit(nil)
            .padding([.top], -5)
        }
      }
      .padding([.leading], 18)
        .padding([.trailing], 30)
        .frame(maxWidth: UIScreen.main.bounds.width)
    })
  }
  
  func playVideo() {
    fetchList()
    print("Play video...")
  }
  
  private func fetchList() {
    
    guard contentDetailsMC.data.groups.isEmpty else { return }
    contentDetailsMC.getContentDetails(for: contentDetailsMC.data.id)
  }
  
  private func buildList() -> AnyView {
      
      let list =
        List {
          ForEach(contentDetailsMC.data.groups, id: \.id) { group in
            Section(header:
              CourseHeaderView(name: group.name, color: .paleGrey)
                .background(Color.paleGrey)
            ) {
              ForEach(group.childContents, id: \.id) { summary in

                TextListItemView(contentSummary: summary, timeStamp: nil, buttonAction: {
                  print("Making my list...")
                })
                  .listRowBackground(Color.paleGrey)
                  .background(Color.paleGrey)
                  .tapAction {
                    self.isPresented = true
                  }
                  .sheet(isPresented: self.$isPresented) { VideoView(videoID: summary.videoID) }
              }
            }
          }
            .listRowBackground(Color.paleGrey)
            .background(Color.paleGrey)
        }
          .background(Color.paleGrey)
          .listRowBackground(Color.paleGrey)
      
      return AnyView(list)
    }
}

struct CourseHeaderView: View {
  let name: String
  let color: Color
  
  var body: some View {
    VStack(alignment: .leading) {
      Spacer()
      HStack {
        Text(name)
          .font(.uiTitle4)
        Spacer()
      }
      Spacer()
    }.padding(0).background(color)
  }
}

struct TopSummaryView: View {
  var details: ContentDetail
  var body: some View {
    VStack(alignment: .leading) {
      
      Text(details.technologyTripleString.uppercased())
        .font(.uiUppercase)
        .foregroundColor(.coolGrey)
        .kerning(0.5)
      // ISSUE: This isn't wrapping to multiple lines, not sure why yet, only .footnote and .caption seem to do it properly without setting a frame? Further investigaiton needed
      
      Text(details.name) // TITLE
        .font(.uiTitle1)
        .lineLimit(nil)
        .frame(idealHeight: .infinity)
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        .padding([.top], -5)
      
      Text(details.dateAndTimeString)
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
      
      HStack {
        Button(action: {
          // Download Action
          self.download()
        }) {
          Image("download")
            .padding([.trailing], 30)
            .foregroundColor(.coolGrey)
        }
        
        Button(action: {
          // Bookmark Action
          self.bookmark()
        }) {
          Image("bookmark")
            .resizable()
            .frame(maxWidth: 20, maxHeight: 20)
            .foregroundColor(.coolGrey)
        }
      }
      .padding([.top], 20)
      
      Text(details.description)
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
        .lineLimit(nil)
        // ISSUE: Below line causes a crash, but somehow the UI renders the text into multiple lines, with the addition of
        // '.frame(idealHeight: .infinity)' to the TITLE...
        //.frame(idealHeight: .infinity)
        .padding([.top], 20)
      
      Text("By \(details.contributorString)")
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
        .lineLimit(2)
        .padding([.top], 5)
    }
  }
  
  private func download() { }
  private func bookmark() { }
}
