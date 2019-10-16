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
import Kingfisher
import UIKit

struct CardView: SwiftUI.View {
  private var onRightIconTap: (() -> Void)?
  private var onLeftIconTap: ((Bool) -> Void)?
  @EnvironmentObject var downloadsMC: DownloadsMC
  var contentScreen: ContentScreen
  @State private var image: UIImage = #imageLiteral(resourceName: "loading")
  private var model: ContentDetailsModel
  private let animation: Animation = .easeIn
  
  init(model: ContentDetailsModel, contentScreen: ContentScreen, onLeftIconTap: ((Bool) -> Void)? = nil, onRightIconTap: (() -> Void)? = nil) {
    self.model = model
    self.onRightIconTap = onRightIconTap
    self.onLeftIconTap = onLeftIconTap
    self.contentScreen = contentScreen
  }
  
  //TODO - Multiline Text: There are some issues with giving views frames that result in .lineLimit(nil) not respecting the command, and
  // results in truncating the text
  var body: some SwiftUI.View {
    
    let stack = VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 15) {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .center) {
            
            Text(model.name)
              .font(.uiTitle4)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .padding([.trailing], 15)
            
            Spacer()
            
            Image(uiImage: self.image)
              .resizable()
              .frame(width: 60, height: 60)
              .onAppear(perform: self.loadImage)
              .transition(.opacity)
              .cornerRadius(6)
          }
          .padding([.top], 10)
          
          Text(model.cardViewSubtitle)
            .font(.uiCaption)
            .lineLimit(nil)
            .foregroundColor(.battleshipGrey)
        }
        
        Text(model.description)
          .font(.uiCaption)
          .fixedSize(horizontal: false, vertical: true)
          .lineLimit(2)
          .foregroundColor(.battleshipGrey)
        
          
          HStack {
            
            if model.professional {
              ProTag()
                .padding([.trailing], 5)
            }
            
            Text(model.technologyTripleString)
              .font(.uiCaption)
              .lineLimit(1)
              .foregroundColor(.battleshipGrey)
            
            Spacer()
            
            HStack(spacing: 18) {
              if model.bookmarked || self.contentScreen == ContentScreen.myTutorials {
                bookmarkButton
              }
              if self.contentScreen != ContentScreen.downloads {
                self.setUpImageAndProgress()
              }
            }
          }
          .padding([.top], 20)
      }
      .padding([.trailing, .leading], 15)
      
      Group {
        ProgressBarView(progress: model.progress)
        
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color.paleBlue)
      }
      .padding([.trailing, .leading], 15)
    }
    .cornerRadius(6)
    .padding([.trailing], 32)
    
    // TODO: If we want to get the card + dropshadow design back, uncomment this
    //    .background(Color.white)
    //    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)
    
    return AnyView(stack)
  }
  
  private var bookmarkButton: AnyView {
    //ISSUE: Changing this from button to "onTapGesture" because the tap target between the download button and thee
    //bookmark button somehow wasn't... clearly defined, so they'd both get pressed when the bookmark button got pressed
    
    let imageName = model.bookmarked ? "bookmarkActive" : "bookmarkInactive"
    
    return AnyView(
      Image(imageName)
        .resizable()
        .frame(width: 21, height: 21)
        .onTapGesture {
          self.bookmark()
      }
    )
  }
  
  private func setUpImageAndProgress() -> AnyView {
    
    let image = Image(self.downloadImageName())
      .resizable()
      .frame(width: 19, height: 19)
      .onTapGesture {
        self.download()
    }
    
    switch downloadsMC.state {
    case .loading:
      
      if model.isInCollection {
        guard let downloadedContent = downloadsMC.downloadedContent,
          downloadedContent.id == model.id else {
            return AnyView(image)
        }
        
        return AnyView(CircularProgressBar(progress: downloadsMC.collectionProgress))
        
      } else {
        // Only show progress on model that is currently being downloaded
        guard let downloadModel = downloadsMC.data.first(where: { $0.content.id == model.id }),
          downloadModel.content.id == downloadsMC.downloadedModel?.content.id else {
            return AnyView(image)
        }
        
        return AnyView(CircularProgressBar(progress: downloadModel.downloadProgress))
      }
      
    default:
      return AnyView(image)
    }
  }
  
  private func download() {
    let success = downloadImageName() != DownloadImageName.inActive
    onLeftIconTap?(success)
  }
  
  private func loadImage() {
    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
    // is causing this file to not compile
    if let imageURL = model.cardArtworkURL {
      fishImage(url: imageURL)
    }
  }
  
  private func fishImage(url: URL) {
    KingfisherManager.shared.retrieveImage(with: url) { result in
      switch result {
      case .success(let imageResult):
        withAnimation(self.animation) {
          self.image = imageResult.image
        }
      case .failure:
        break
      }
    }
  }
  
  private func downloadImageName() -> String {
    
    if model.isInCollection {
      
      return downloadsMC.data.contains { downloadModel in
        
        return downloadModel.content.parentContentId == model.id
        } ? DownloadImageName.inActive : DownloadImageName.active
    } else {
      return downloadsMC.data.contains(where: { $0.content.id == model.id }) ? DownloadImageName.inActive : DownloadImageName.active
    }
  }
  
  private func createEmptyView() -> AnyView {
    let vStack = VStack {
      HStack {
        Spacer()
        
        Text(contentScreen.titleMessage)
          .font(.uiTitle2)
          .foregroundColor(.appBlack)
          .multilineTextAlignment(.center)
          .lineLimit(nil)
        
        Spacer()
      }
      
      addDetailText()
    }
    
    return AnyView(vStack)
  }
  
  private func addDetailText() -> AnyView? {
    guard let detail = contentScreen.detailMesage else { return nil }
    let stack = HStack {
      Spacer()
      
      Text(detail)
        .font(.uiHeadline)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
      
      Spacer()
    }
    
    return AnyView(stack)
  }
  
  private func bookmark() {
    onRightIconTap?()
  }
}
