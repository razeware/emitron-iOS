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

private enum Layout {
  static let buttonSize: CGFloat = 21
}

struct ContentSummaryView: View {
  var content: ContentListDisplayable
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel
  @EnvironmentObject var sessionController: SessionController
  
  var courseLocked: Bool {
    content.professional && !sessionController.user!.canStreamPro
  }
  
  var canDownload: Bool {
    sessionController.user?.canDownload ?? false
  }
  
  var body: some View {
    dynamicContentViewModel.initialiseIfRequired()
    return contentView
  }
  
  private var contentView: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(content.technologyTripleString.uppercased())
          .font(.uiUppercase)
          .foregroundColor(.contentText)
          .kerning(0.5)
        // ISSUE: This isn't wrapping to multiple lines, not sure why yet, only .footnote and .caption seem to do it properly without setting a frame? Further investigaiton needed
        Spacer()
        
        if content.professional {
          ProTag()
        }
      }
      .padding([.top], 20)
      
      Text(content.name)
        .font(.uiTitle1)
        .lineLimit(nil)
        //.frame(idealHeight: .infinity) // ISSUE: This line is causing a crash
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 10)
        .foregroundColor(.titleText)
      
      Text(content.contentSummaryMetadataString)
        .font(.uiCaption)
        .foregroundColor(.contentText)
        .lineSpacing(3)
        .padding([.top], 10)
      
      if !courseLocked {
        HStack(spacing: 30, content: {
          if canDownload {
            DownloadIcon(downloadProgress: dynamicContentViewModel.downloadProgress)
              .onTapGesture {
                self.download()
              }
          }
          
          bookmarkButton
          
          completedTag
        })
          .padding([.top], 15)
      }
      
      Text(content.descriptionPlainText)
        .font(.uiCaption)
        .foregroundColor(.contentText)
        .lineSpacing(3)
        // ISSUE: Below line causes a crash, but somehow the UI renders the text into multiple lines, with the addition of
        // '.frame(idealHeight: .infinity)' to the TITLE...
        //.frame(idealHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 15)
        .lineLimit(nil)
      
      Text("By \(content.contributorString)")
        .font(.uiFootnote)
        .foregroundColor(.contentText)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 10)
        .lineSpacing(3)
    }
  }
  
  private var completedTag: CompletedTag? {
    if case .completed = dynamicContentViewModel.viewProgress {
      return CompletedTag()
    }
    return nil
  }
  
  private var bookmarkButton: AnyView {
    //ISSUE: Changing this from button to "onTapGesture" because the tap target between the download button and thee
    //bookmark button somehow wasn't... clearly defined, so they'd both get pressed when the bookmark button got pressed
    
    let imageName = dynamicContentViewModel.bookmarked ? "bookmarkActive" : "bookmarkInactive"
    
    return AnyView(
      Image(imageName)
        .resizable()
        .frame(width: Layout.buttonSize, height: Layout.buttonSize)
        .onTapGesture {
          self.bookmark()
        }
    )
  }
  
  private func download() {
    dynamicContentViewModel.downloadTapped()
  }
  
  private func bookmark() {
    dynamicContentViewModel.bookmarkTapped()
  }
}
