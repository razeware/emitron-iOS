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
  
  var contentSummaryMC: ContentSummaryMC
  var callback: ((ContentSummaryModel)->())?
  var user: UserModel
  
  @State var isPresented = false
  @State var uiImage: UIImage = #imageLiteral(resourceName: "loading")
  var imageRatio: CGFloat = 283/375
  
  func topView() -> some View {
    return Text("Hola!")
  }
  
  var body: some View {
    
    loadImage()
    
    let list = GeometryReader { geometry in
      
      if self.contentSummaryMC.data.contentType == .collection {
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        
        VStack {
          Text("Course Episodes")
            .font(.uiTitle2)
            .padding([.top], -5)
          
          //          ForEach(contentDetailsMC.data.groups, id: \.id) { group in
          //            Section(header:
          //              CourseHeaderView(name: group.name, color: .white)
          //                .background(Color.white)
          //            ) {
          //              ForEach(group.childContents, id: \.id) { summary in
          //
          //                TextListItemView(contentSummary: summary, timeStamp: "", buttonAction: {
          //                  // Download
          //                })
          //                  .onTapGesture {
          //                    self.isPresented = true
          //                }
          //                .sheet(isPresented: self.$isPresented) { VideoView(videoID: summary.videoID, user: self.user) }
          //              }
          //            }
          //          }
          // TODO: Ask Lea & Sam about this...
          //          ForEach(contentSummaryMC.data.groups, id: \.id) { group in
          //            Section(header:
          //              CourseHeaderView(name: group.name, color: .white)
          //                .background(Color.white)
          //            ) {
          //              ForEach(group.childContents, id: \.id) { summary in
          //
          //                TextListItemView(contentSummary: summary, timeStamp: "", buttonAction: {
          //                  // Download
          //                })
          //                .onTapGesture {
          //                  self.isPresented = true
          //                }
          //                .sheet(isPresented: self.$isPresented) { VideoView(videoID: summary.videoID, user: self.user) }
          //              }
          //            }
          //          }
        }
      } else {
        Button(action: {
          self.isPresented = true
        }) {
          Text("Play Video!")
            //TODO: This is wrong
            .sheet(isPresented: self.$isPresented) { VideoView(videoID: self.contentSummaryMC.data.videoID, user: self.user) }
        }
      }
    }
    
    let scrollView = GeometryReader { geometry in
      ScrollView(.vertical, showsIndicators: false) {
        VStack {
          Image(uiImage: self.uiImage)
            .resizable()
            .frame(width: geometry.size.width, height: geometry.size.width * self.imageRatio)
            .transition(.opacity)

          ContentSummaryView(callback: self.callback, details: self.contentSummaryMC.data)
            .padding([.leading, .trailing], 20)

          list
        }
        .background(Color.paleGrey)
      }
    }
    
    return scrollView
  }

//  private func loadImageAlt() -> some View {
//    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
//    // is causing this file to not compile
//
//    //TODO: This is probably not the right way tohandle image change, only doing this because the .onAppear trigger doesn't work for modals...
//    let image = Image(uiImage: uiImage)
//      .resizable()
//      .frame(width: 375, height: 283)
//
//    guard let url = contentDetailsMC.data.cardArtworkURL else {
//      return AnyView(image)
//    }
//
//    if !imageLoaded {
//      DispatchQueue.global().async {
//        let data = try? Data(contentsOf: url)
//        DispatchQueue.main.async {
//          if let data = data,
//            let img = UIImage(data: data) {
//            self.uiImage = img
//            self.imageLoaded.toggle()
//          }
//        }
//      }
//    }
//  }

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
        //          self.imageLoaded.toggle()
      }
    }
  }
}
}
