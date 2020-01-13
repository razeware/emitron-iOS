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
import KingfisherSwiftUI

struct CardView: View {
  let model: ContentListDisplayable
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel
  private let animation: Animation = .easeIn

  //TODO - Multiline Text: There are some issues with giving views frames that result in .lineLimit(nil) not respecting the command, and
  // results in truncating the text
  var body: some View {
    dynamicContentViewModel.initialiseIfRequired()
    let stack = VStack(alignment: .leading) {
      VStack(alignment: .leading, spacing: 15) {
        VStack(alignment: .leading, spacing: 0) {
          HStack(alignment: .center) {

            Text(name)
              .font(.uiTitle4)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .padding([.trailing], 15)
              .foregroundColor(.titleText)

            Spacer()

            KFImage(model.cardArtworkUrl)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 60, height: 60)
              .transition(.opacity)
              .cornerRadius(6)
          }
          .padding([.top], 10)
          
          Text(model.cardViewSubtitle)
            .font(.uiCaption)
            .lineLimit(nil)
            .foregroundColor(.contentText)
        }
        
        Text(model.descriptionPlainText)
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
          
          proTagOrReleasedAt
          
          Spacer()
          
          HStack(spacing: 18) {
            bookmarkButton
          }
        }
        .padding([.top], 20)
      }
      .padding([.trailing, .leading], 15)
      
      SwiftUI.Group {
        progressBar
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
  
  private var name: String {
    guard let parentName = model.parentName, model.contentType == .episode else {
      return model.name
    }
    
    return "\(parentName): \(model.name)"
  }
  
  private var progressBar: AnyView {
    if case .inProgress(let progress) = dynamicContentViewModel.viewProgress {
      return AnyView(ProgressBarView(progress: progress, isRounded: true)
        .padding([.top, .bottom], 0))
    } else {
      return AnyView(Rectangle()
        .frame(height: 1)
        .foregroundColor(.separator)
        .padding([.top, .bottom], 0)
        .cornerRadius(6))
    }
  }
  
  private var proTagOrReleasedAt: AnyView {
    if case .completed = dynamicContentViewModel.viewProgress {
      return AnyView(CompletedTag())
    } else {
      return AnyView(Text(model.releasedAtDateTimeString)
        .font(.uiCaption)
        .lineLimit(1)
        .foregroundColor(.contentText))
    }
  }
  
  private var bookmarkButton: AnyView? {
    guard dynamicContentViewModel.bookmarked else { return nil }
    
    return AnyView(
      Image("bookmarkActive")
        .resizable()
        .frame(width: 21, height: 21)
    )
  }
}
