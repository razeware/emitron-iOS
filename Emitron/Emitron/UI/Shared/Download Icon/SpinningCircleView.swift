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

private enum Layout {
  static let lineWidth: CGFloat = 2
}

struct SpinningCircleView: View {
  @State private var animateRotation = false
  @State private var animateStrokeStart = true
  @State private var animateStrokeEnd = true
  
  var body: some View {
    ZStack {
      background
      circleOverlay
    }
  }
  
  var background: some View {
    ZStack(alignment: .center) {
      Circle()
        .stroke(Color.downloadButtonDownloadingBackground, lineWidth: Layout.lineWidth)
        .frame(width: DownloadIconLayout.size, height: DownloadIconLayout.size)
      
      RoundedRectangle(cornerRadius: 1)
        .fill(Color.downloadButtonDownloadingBackground)
        .frame(width: 6, height: 6)
    }
  }

  var circleOverlay: some View {
    Circle()
      .trim(
        from: animateStrokeStart ? 0.2 : 0.1,
        to: animateStrokeEnd ? 0.2 : 0.5
      )
      .stroke(Color.downloadButtonDownloadingForeground, lineWidth: Layout.lineWidth)
      .frame(width: DownloadIconLayout.size, height: DownloadIconLayout.size)
      .rotationEffect(.degrees(animateRotation ? 360 : 0))
      .onAppear {
        withAnimation(
          Animation
            .linear(duration: 1)
            .repeatForever(autoreverses: false)
        ) {
          self.animateRotation.toggle()
        }
        
        withAnimation(
          Animation
            .linear(duration: 1)
            .delay(0.5)
            .repeatForever(autoreverses: true)
        ) {
          self.animateStrokeStart.toggle()
        }
        
        withAnimation(
          Animation
            .linear(duration: 1)
            .delay(1)
            .repeatForever(autoreverses: true)
        ) {
          self.animateStrokeEnd.toggle()
        }
      }
  }
}

struct SpinningCircleView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      spinners.colorScheme(.dark)
      spinners.colorScheme(.light)
    }
  }
  
  static var spinners: some View {
    SpinningCircleView()
      .padding()
      .background(Color.backgroundColor)
  }
}
