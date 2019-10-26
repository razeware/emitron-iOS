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

private extension CGFloat {
  static let horizontalSpacing: CGFloat = 15
  static let buttonSide: CGFloat = 30
}

struct TextListItemView: View {
  // It's fine that this child view isn't observing this parameter, because the parent is, so the changes will trickle down through the requests
  // Good thought to have when creating the architecture for non-networking based views
  var contentSummary: ContentDetailsModel
  var buttonAction: (Bool) -> Void
  @ObservedObject var downloadsMC: DownloadsMC
  @ObservedObject var progressionsMC: ProgressionsMC
  
  var canStreamPro: Bool {
    return Guardpost.current.currentUser?.canStream ?? false
  }
  var canDownload: Bool {
    return Guardpost.current.currentUser?.canDownload ?? false
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: .horizontalSpacing) {
        
        doneCheckbox
        
        Text(contentSummary.name)
          .font(.uiTitle5)
          .fixedSize(horizontal: false, vertical: true)
        
        Spacer()
        
        if canDownload {
          setUpImageAndProgress()
            .padding([.trailing], 20)
        }
      }
      
      Text(contentSummary.duration.minuteSecondTimeFromSeconds)
        .font(.uiCaption)
        .padding([.leading], CGFloat.horizontalSpacing + CGFloat.buttonSide)
        .padding([.top], 2)
      
      if contentSummary.progress < 1.0 && contentSummary.progress > 0.0 {
        ProgressBarView(progress: contentSummary.progress, isRounded: true)
          .padding([.leading], CGFloat.horizontalSpacing + CGFloat.buttonSide)
          .padding([.trailing], 20)
          .padding([.top], 10)
      }
    }
  }
  
  private func setUpImageAndProgress() -> AnyView {
    
    let image = Image(self.downloadImageName)
      .resizable()
      .frame(width: 19, height: 19)
      .onTapGesture {
        self.download()
    }
    
    switch downloadsMC.state {
    case .loading:

      if contentSummary.isInCollection {
        
        // If downloading entire collection, only showing loading view at the top of the ContentsListingView
        guard downloadsMC.isEpisodeOnly else {
          return AnyView(image)
        }
        
        guard let downloadedContent = downloadsMC.downloadedContent,
        downloadedContent.id == contentSummary.id else {
          return AnyView(image)
        }
        
        return AnyView(CircularProgressBar(isCollection: true, progress: downloadsMC.collectionProgress))

      } else {
        // Only show progress on model that is currently being downloaded
        guard let downloadModel = downloadsMC.data.first(where: { $0.content.id == contentSummary.id }),
              downloadModel.content.id == downloadsMC.downloadedModel?.content.id else {
          return AnyView(image)
        }
        
        return AnyView(CircularProgressBar(isCollection: false, progress: downloadModel.downloadProgress))
      }
      
    default:
      return AnyView(image)
    }
  }
  
  private var downloadImageName: String {
    if contentSummary.isInCollection {
      return downloadsMC.data.contains { downloadModel in
        return downloadModel.content.id == contentSummary.id
        } ? DownloadImageName.inActive : DownloadImageName.active
    } else {
      return downloadsMC.data.contains(where: { $0.content.id == contentSummary.id }) ? DownloadImageName.inActive : DownloadImageName.active
    }
  }
  
  private func download() {
    let success = downloadImageName != DownloadImageName.inActive
    buttonAction(success)
  }
  
  private var doneCheckbox: AnyView {
    
    if !canDownload && contentSummary.professional {
      return AnyView(ZStack {
        Rectangle()
          .frame(width: .buttonSide, height: .buttonSide, alignment: .center)
          .foregroundColor(.secondaryButtonBackground)
          .cornerRadius(6)
        
        Image("padlock")
          .frame(width: 10, height: 15, alignment: .center)
      })
    }

    let numberView = ZStack {
      Rectangle()
        .frame(width: .buttonSide, height: .buttonSide, alignment: .center)
        .foregroundColor(.secondaryButtonBackground)
        .cornerRadius(6)
      
      Text("\(contentSummary.index ?? 0)")
        .font(.uiButtonLabelSmall)
        .foregroundColor(.buttonText)
    }
    .onTapGesture {
      self.toggleCompleteness()
    }
    
    let completeView = ZStack(alignment: .center) {
      Rectangle()
        .frame(width: .buttonSide, height: .buttonSide)
        .foregroundColor(Color.accent)
        .cornerRadius(6)
      
      Image("checkmark")
        .resizable()
        .frame(maxWidth: 15, maxHeight: 17)
        .foregroundColor(Color.buttonText)
    }
    
    guard let progression = contentSummary.progression, progression.finished else {
      return AnyView(numberView)
    }
    return AnyView(completeView)
  }
  
  private func toggleCompleteness() {
    print("Make me complete!!!")
  }
}
