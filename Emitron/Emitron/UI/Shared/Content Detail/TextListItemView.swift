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
  @EnvironmentObject var sessionController: SessionController
  
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel
  var content: ChildContentListDisplayable
  
  var canStreamPro: Bool {
    return sessionController.user?.canStreamPro ?? false
  }
  var canDownload: Bool {
    return sessionController.user?.canDownload ?? false
  }
  
  var body: some View {
    dynamicContentViewModel.initialiseIfRequired()
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: .horizontalSpacing) {
        
        doneCheckbox
        
        Text(content.name)
          .font(.uiTitle5)
          .fixedSize(horizontal: false, vertical: true)
        
        Spacer()
        
        if canDownload {
          DownloadIcon(downloadProgress: dynamicContentViewModel.downloadProgress)
            .onTapGesture {
              self.download()
            }
            .padding([.trailing], 20)
        }
      }
      
      Text(content.duration.minuteSecondTimeFromSeconds)
        .font(.uiCaption)
        .padding([.leading], CGFloat.horizontalSpacing + CGFloat.buttonSide)
        .padding([.top], 2)
      
      progressBar
    }
  }
  
  private var progressBar: AnyView? {
    guard case .inProgress(let progress) = dynamicContentViewModel.viewProgress else { return nil }
    return AnyView(
      ProgressBarView(progress: progress, isRounded: true)
        .padding([.leading], CGFloat.horizontalSpacing + CGFloat.buttonSide)
        .padding([.trailing], 20)
        .padding([.top], 10)
    )
  }
  
  private var doneCheckbox: AnyView {
    
    if !canDownload && content.professional {
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
      
      Text("\(content.ordinal ?? 0)")
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
    
    if case .completed = dynamicContentViewModel.viewProgress {
      return AnyView(completeView)
    }
    
    return AnyView(numberView)
  }
  
  private func download() {
    dynamicContentViewModel.downloadTapped()
  }
  
  private func toggleCompleteness() {
    dynamicContentViewModel.completedTapped()
  }
}
