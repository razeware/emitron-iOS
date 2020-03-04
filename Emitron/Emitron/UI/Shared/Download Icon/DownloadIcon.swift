// Copyright (c) 2020 Razeware LLC
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

enum DownloadIconLayout {
  static let size: CGFloat = 20
  static let lineWidth: CGFloat = 2
}

struct DownloadIcon: View {
  let downloadProgress: DownloadProgressDisplayable
  
  var body: some View {
    icon.frame(width: DownloadIconLayout.size, height: DownloadIconLayout.size)
  }
  
  var icon: some View {
    switch downloadProgress {
    case .downloadable:
      return AnyView(ArrowInCircleView(fillColour: .downloadButtonNotDownloaded))
    case .enqueued:
      return AnyView(SpinningCircleView())
    case .inProgress(progress: let progress):
      return AnyView(CircularProgressBar(progress: progress))
    case .downloaded:
      return AnyView(ArrowInCircleView(fillColour: .downloadButtonDownloaded))
    case .notDownloadable:
      return AnyView(DownloadWarningView())
    }
  }
}

struct DownloadIcon_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      selectionList.colorScheme(.light)
      selectionList.colorScheme(.dark)
    }
  }
  
  static var selectionList: some View {
    VStack {
      icon(for: .downloadable)
      icon(for: .enqueued)
      icon(for: .inProgress(progress: 0.3))
      icon(for: .inProgress(progress: 0.7))
      icon(for: .inProgress(progress: 0.8))
      icon(for: .downloaded)
      icon(for: .notDownloadable)
    }
      .padding(20)
      .background(Color.backgroundColor)
  }
  
  static func icon(for state: DownloadProgressDisplayable) -> some View {
    HStack {
      Text(state.description)
      DownloadIcon(downloadProgress: state)
    }
  }
}
