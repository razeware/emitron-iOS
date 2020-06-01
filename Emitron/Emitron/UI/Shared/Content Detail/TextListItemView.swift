// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import SwiftUI

extension CGFloat {
  static let childContentHorizontalSpacing: CGFloat = 15
  static let childContentButtonSide: CGFloat = 30
}

struct TextListItemView: View {
  @EnvironmentObject var sessionController: SessionController
  @State private var deletionConfirmation: DownloadDeletionConfirmation?
  
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel
  var content: ChildContentListDisplayable
  
  var canStreamPro: Bool {
    sessionController.user?.canStreamPro ?? false
  }
  var canDownload: Bool {
    sessionController.user?.canDownload ?? false
  }
  
  var body: some View {
    dynamicContentViewModel.initialiseIfRequired()
    return HStack(alignment: .top, spacing: .childContentHorizontalSpacing) {
      doneCheckbox
      
      VStack(spacing: 15) {
        HStack {
          VStack(alignment: .leading, spacing: 5) {
            Text(content.name)
              .font(.uiTitle5)
              .lineSpacing(3)
              .foregroundColor(.titleText)
            
            Text(content.duration.minuteSecondTimeFromSeconds)
              .font(.uiFootnote)
              .foregroundColor(.contentText)
          }
            
          Spacer()
            
          if canDownload {
            DownloadIcon(downloadProgress: dynamicContentViewModel.downloadProgress)
              .onTapGesture {
                self.download()
              }
              .alert(item: $deletionConfirmation, content: \.alert)
          }
        }
        progressBar
      }
    }
  }
  
  private var progressBar: AnyView {
    guard case .inProgress(let progress) = dynamicContentViewModel.viewProgress else {
      return AnyView(Rectangle()
        .frame(height: 1)
        .foregroundColor(.borderColor))
    }
    return AnyView(
      ProgressBarView(progress: progress, isRounded: true)
    )
  }
  
  private var doneCheckbox: AnyView {
    if !canStreamPro && content.professional {
      return AnyView(LockedIconView())
    }
    
    if case .completed = dynamicContentViewModel.viewProgress {
      return AnyView(
        CompletedIconView()
          .onTapGesture {
            self.toggleCompleteness()
          }
      )
    } else {
      return AnyView(
        NumberIconView(number: content.ordinal ?? 0)
          .onTapGesture {
            self.toggleCompleteness()
          }
      )
    }
  }
  
  private func download() {
    deletionConfirmation = dynamicContentViewModel.downloadTapped()
  }
  
  private func toggleCompleteness() {
    dynamicContentViewModel.completedTapped()
  }
}
