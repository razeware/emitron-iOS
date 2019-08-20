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
  
  @ObservedObject var contentDetailsMC: ContentDetailsMC
  @State var isPresented = false
  @State private var uiImage: UIImage = #imageLiteral(resourceName: "loading")
  @Binding var imageLoaded: Bool
  
  var user: UserModel
  
  var body: some View {
    
    List {
      VStack {
  
        Image("loading")
          .fetchingRemoteImage(from: contentDetailsMC.data.cardArtworkURL!)
          .frame(width: 375, height: 283)
        
        ContentSummaryView(details: contentDetailsMC.data)
      }
      .frame(maxWidth: UIScreen.main.bounds.width)
      .background(Color.white)
      
      if contentDetailsMC.data.contentType == .collection {
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        
        VStack {
          Text("Course Episodes")
            .font(.uiTitle2)
            .padding([.top], -5)
          
          ForEach(contentDetailsMC.data.groups, id: \.id) { group in
            Section(header:
              CourseHeaderView(name: group.name, color: .white)
                .background(Color.white)
            ) {
              ForEach(group.childContents, id: \.id) { summary in
                
                TextListItemView(contentSummary: summary, timeStamp: "", buttonAction: {
                  // Download
                })
                  .onTapGesture {
                    self.isPresented = true
                }
                .sheet(isPresented: self.$isPresented) { VideoView(videoID: summary.videoID, user: self.user) }
              }
            }
          }
        }
      } else {
        Button(action: {
          self.isPresented = true
        }) {
          Text("Play Video!")
            .sheet(isPresented: self.$isPresented) { VideoView(videoID: self.contentDetailsMC.data.videoID!, user: self.user) }
        }
      }
    }
    .onAppear {
      //TODO: Kind of hack to force data-reload while this modal-presentation with List issue goes on
      self.contentDetailsMC.getContentDetails()
    }
    .onDisappear {
      print("I'm gone...")
    }
  }
  
  private func loadImage() -> AnyView {
    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
    // is causing this file to not compile
    
    //TODO: This is probably not the right way tohandle image change, only doing this because the .onAppear trigger doesn't work for modals...
    let image = Image(uiImage: uiImage)
      .resizable()
      .frame(width: 375, height: 283)
    
    guard let url = contentDetailsMC.data.cardArtworkURL else {
      return AnyView(image)
    }
    
    if !imageLoaded {
      DispatchQueue.global().async {
        let data = try? Data(contentsOf: url)
        DispatchQueue.main.async {
          if let data = data,
            let img = UIImage(data: data) {
            self.uiImage = img
            self.imageLoaded.toggle()
          }
        }
      }
    }
    return AnyView(image)
  }
}
