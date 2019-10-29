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
import Network

struct CardView: SwiftUI.View {
  @State private var image: UIImage = #imageLiteral(resourceName: "loading")
  private var model: ContentDetailsModel
  private let animation: Animation = .easeIn
  private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)

  init(model: ContentDetailsModel) {
    self.model = model
  }

  //TODO - Multiline Text: There are some issues with giving views frames that result in .lineLimit(nil) not respecting the command, and
  // results in truncating the text
  var body: some SwiftUI.View {

    setUpNetworkMonitor()

    let stack = VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 15) {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .center) {

            Text(model.name)
              .font(.uiTitle4)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .padding([.trailing], 15)
              .foregroundColor(.titleText)

            Spacer()

            Image(uiImage: self.image)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 60, height: 60)
              .onAppear(perform: self.loadImage)
              .transition(.opacity)
              .cornerRadius(6)
          }
          .padding([.top], 10)

          Text(model.cardViewSubtitle)
            .font(.uiCaption)
            .lineLimit(nil)
            .foregroundColor(.contentText)
        }

        Text(model.desc)
          .font(.uiCaption)
          .fixedSize(horizontal: false, vertical: true)
          .lineLimit(2)
          .lineSpacing(3)
          .foregroundColor(.contentText)

        HStack {

          if model.professional {
            ProTag()
              .padding([.trailing], 5)
          }

          if model.progress >= 1 {
            CompletedTag()
          } else {
            Text(model.releasedAtDateTimeString)
              .font(.uiCaption)
              .lineLimit(1)
              .foregroundColor(.contentText)
          }

          Spacer()

          HStack(spacing: 18) {
            bookmarkButton
          }
        }
        .padding([.top], 20)
      }
      .padding([.trailing, .leading], 15)

      Group {
        if model.progress > 0 && model.progress < 1 {
          ProgressBarView(progress: model.progress, isRounded: true)
            .padding([.top, .bottom], 0)
        } else {
          Rectangle()
            .frame(height: 1)
            .foregroundColor(.separator)
            .padding([.top, .bottom], 0)
            .cornerRadius(6)
        }
      }
      .padding([.trailing, .leading], 15)
      .padding([.top], 10)
    }
    .cornerRadius(6)
    .padding([.trailing], 32)

    // TODO: If we want to get the card + dropshadow design back, uncomment this
    //    .background(Color.white)
    //    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)

    return AnyView(stack)
  }

  private var bookmarkButton: AnyView? {
    //ISSUE: Changing this from button to "onTapGesture" because the tap target between the download button and thee
    //bookmark button somehow wasn't... clearly defined, so they'd both get pressed when the bookmark button got pressed
    
    guard model.bookmarked else { return nil }

    let imageName = model.bookmarked ? "bookmarkActive" : "bookmarkInactive"

    return AnyView(
      Image(imageName)
        .resizable()
        .frame(width: 21, height: 21)
    )
  }

  private func setUpNetworkMonitor() {
    let queue = DispatchQueue(label: "Monitor")
    monitor.start(queue: queue)
  }

  private func loadImage() {
    //TODO: Will be uising Kingfisher for this, for performant caching purposes, but right now just importing the library
    // is causing this file to not compile
    if let imageURL = model.cardArtworkURL {
      fishImage(url: imageURL)
    } else if let data = model.cardArtworkData, let uiImage = UIImage(data: data) {
      self.image = uiImage
    }
  }

  private func fishImage(url: URL) {
    KingfisherManager.shared.retrieveImage(with: url) { result in
      switch result {
      case .success(let imageResult):
        self.image = imageResult.image
      case .failure:
        break
      }
    }
  }
}
