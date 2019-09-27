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

enum CardViewType: Hashable {
  case `default`
  case bookmark
}

enum ImageType: Hashable {
  case asset(UIImage)
  case url(URL)
}

// Shuold be data model independent, so that we can transform any type of data into the cardViewModel data
struct CardViewModel: Hashable {
  let title: String
  let subtitle: String
  let description: String
  let imageType: ImageType
  let footnote: String
  let type: CardViewType
  let progress: CGFloat
  let isDownloaded: Bool
}

// Transform data
extension CardViewModel {
  static func transform(_ content: ContentSummaryModel, cardViewType: CardViewType) -> CardViewModel? {
    guard let domainData = DataManager.current?.domainsMC.data else {
      return nil
    }

    let ids = content.domainIDs
    let contentDomains = domainData.filter { ids.contains($0.id) }
    let subtitle = contentDomains.map { $0.name }.joined(separator: ", ")
    let isDownloaded = content.isDownloaded

    var progress: CGFloat = 0
    if let progression = content.progression {
      progress = progression.finished ? 1 : CGFloat(progression.percentComplete / 100)
    }

    var imageType: ImageType

    if let imageURL = content.cardArtworkURL {
      imageType = ImageType.url(imageURL)
    } else {
      imageType = ImageType.asset(#imageLiteral(resourceName: "loading"))
    }

    let cardModel = CardViewModel(title: content.name, subtitle: subtitle, description: content.description, imageType: imageType, footnote: content.releasedAtDateTimeString, type: cardViewType, progress: progress, isDownloaded: isDownloaded)

    return cardModel
  }
}

struct CardView: SwiftUI.View {

  var onRightIconTap: (() -> Void)?
  var contentScreen: ContentScreen
  @State private var image: UIImage = #imageLiteral(resourceName: "loading")
  private var model: CardViewModel?
  private let animation: Animation = .easeIn

  init(model: CardViewModel?, contentScreen: ContentScreen, onRightIconTap: (() -> Void)? = nil) {
    self.model = model
    self.onRightIconTap = onRightIconTap
    self.contentScreen = contentScreen
  }

  //TODO - Multiline Text: There are some issues with giving views frames that result in .lineLimit(nil) not respecting the command, and
  // results in truncating the text
  var body: some SwiftUI.View {
    guard let model = model else {
      let emptyView = AnyView(createEmptyView())
      return emptyView
    }
    
    let stack = GeometryReader { geometry in
      VStack {
        VStack(alignment: .leading) {
          VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .center) {
                
                Text(model.title)
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
              
              Text(model.subtitle)
                .font(.uiCaption)
                .lineLimit(nil)
                .foregroundColor(.battleshipGrey)
            }
            
            Text(model.description)
              .font(.uiCaption)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(3)
              .foregroundColor(.battleshipGrey)
            
            HStack {
              Text(model.footnote)
                .font(.uiCaption)
                .lineLimit(1)
                .foregroundColor(.battleshipGrey)
              
              Spacer()
              
              if self.contentScreen != ContentScreen.downloads {
                Image(self.downloadImageName())
                  .resizable()
                  .frame(width: 19, height: 19)
                  .onTapGesture {
                    self.download()
                }
              }
            }
          }
          .padding([.leading, .trailing, .top, .bottom], 15)
          .frame(minHeight: 184)
          
          Spacer()
          
          ProgressBarView(progress: model.progress)
        }
      }
      .frame(minWidth: geometry.size.width * 0.9, minHeight: geometry.size.width * 0.9 * 0.57)
      .background(Color.white)
      .cornerRadius(6)
      .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)
    }
    
    return AnyView(stack)
  }

  private func download() {
    guard downloadImageName() != DownloadImageName.inActive else {
      // TODO show hud stating already downloaded
      return
    }
    
    onRightIconTap?()
  }

  private func loadImage() {
    guard let model = model else { return }
    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
    // is causing this file to not compile
    switch model.imageType {
    case .asset(let img):
      image = img
    case .url(let url):
//      DispatchQueue.global().async {
//        let data = try? Data(contentsOf: url)
//        if let data = data,
//          let img = UIImage(data: data) {
//          DispatchQueue.main.async {
//            self.image = img
//          }
//        }
//      }
      fishImage(url: url)
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
    guard let model = model else { return DownloadImageName.inActive }
    return model.isDownloaded ? DownloadImageName.inActive : DownloadImageName.active
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
}

#if DEBUG
struct CardView_Previews: PreviewProvider {
  static var previews: some SwiftUI.View {
    let cardModel = CardViewModel.transform(ContentSummaryModel.test, cardViewType: .default)!
    return CardView(model: cardModel, contentScreen: .library, onRightIconTap: nil)
  }
}
#endif
