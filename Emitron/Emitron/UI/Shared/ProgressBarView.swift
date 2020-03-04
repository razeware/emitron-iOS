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

struct ProgressBarView: View {
  let progress: Double // Between 0.0 and 1.0
  let isRounded: Bool
  var backgroundColor: Color = .borderColor
  var height: CGFloat = 4

  var adjustedProgress: CGFloat {
    progress < 0.05 ? 0.05 : CGFloat(progress)
  }
  
  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .frame(width: geometry.size.width, height: self.height)
        .foregroundColor(self.backgroundColor)
        .cornerRadius(self.isRounded ? self.height / 2 : 0)
        .overlay(
          ZStack(alignment: .leading) {
            Rectangle()
              .frame(width: geometry.size.width * self.adjustedProgress, height: self.height)
              .foregroundColor(.accent)
              .cornerRadius(self.height / 2)
            
            if !self.isRounded {
              Rectangle()
                .frame(width: self.height, height: self.height)
                .foregroundColor(.accent)
            }
          },
          alignment: .leading
        )
    }.frame(height: self.height)
  }
}

#if DEBUG
struct ProgressBarView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      bars.colorScheme(.light)
      bars.colorScheme(.dark)
    }
  }
  
  static var bars: some View {
    VStack(spacing: 20) {
      ProgressBarView(progress: 0.3, isRounded: true)
      ProgressBarView(progress: 0.6, isRounded: true)
      ProgressBarView(progress: 1.0, isRounded: true)
      ProgressBarView(progress: 0.3, isRounded: false)
      ProgressBarView(progress: 0.6, isRounded: false)
      ProgressBarView(progress: 0.9, isRounded: false)
      ProgressBarView(progress: 0.3, isRounded: true, backgroundColor: .clear)
      ProgressBarView(progress: 0.6, isRounded: true, backgroundColor: .clear)
      ProgressBarView(progress: 1.0, isRounded: true, backgroundColor: .clear)
    }
      .padding()
      .background(Color.backgroundColor)
  }
}
#endif
