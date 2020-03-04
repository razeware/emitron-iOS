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

struct CircularProgressBar: View {
  var progress: Double

  var body: some View {
    ZStack {
      background
      circleOverlay
    }
  }
  
  var background: some View {
    ZStack(alignment: .center) {
      Circle()
        .stroke(Color.downloadButtonDownloadingBackground, lineWidth: DownloadIconLayout.lineWidth)
        .frame(width: DownloadIconLayout.size, height: DownloadIconLayout.size)
      
      RoundedRectangle(cornerRadius: 1)
        .fill(Color.downloadButtonDownloadingForeground)
        .frame(width: 6, height: 6)
    }
  }

  var circleOverlay: some View {
    Circle()
      .trim(from: 0.0, to: CGFloat(progress))
      .stroke(Color.downloadButtonDownloadingForeground, lineWidth: DownloadIconLayout.lineWidth)
      .frame(width: DownloadIconLayout.size, height: DownloadIconLayout.size)
      .rotationEffect(.degrees(-90), anchor: .center)
  }
}

struct CircularProgressIndicator_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      progressViews.colorScheme(.dark)
      progressViews.colorScheme(.light)
    }
  }
  
  static var progressViews: some View {
    HStack(spacing: 20) {
      CircularProgressBar(progress: 0)
      CircularProgressBar(progress: 0.2)
      CircularProgressBar(progress: 0.4)
      CircularProgressBar(progress: 0.6)
      CircularProgressBar(progress: 0.8)
      CircularProgressBar(progress: 1)
    }
      .padding(20)
      .background(Color.backgroundColor)
  }
}
