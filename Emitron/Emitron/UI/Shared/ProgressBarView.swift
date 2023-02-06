// Copyright (c) 2022 Kodeco Inc

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

struct ProgressBarView {
  /// - Parameter progress: Between 0.0 and 1.0
  init(
    progress: Double,
    isRounded: Bool,
    backgroundColor: Color = .borderColor
  ) {
    self.progress = progress
    self.isRounded = isRounded
    self.backgroundColor = backgroundColor
  }
  
  private let progress: Double // Between 0.0 and 1.0
  private let isRounded: Bool
  private let backgroundColor: Color
  private let height: CGFloat = 4
}

// MARK: - View
extension ProgressBarView: View {
  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .frame(width: geometry.size.width, height: height)
        .foregroundColor(backgroundColor)
        .cornerRadius(isRounded ? height / 2 : 0)
        .overlay(
          ZStack(alignment: .leading) {
            let adjustedProgress = max(progress, 0.05)
            Rectangle()
              .frame(width: geometry.size.width * adjustedProgress, height: height)
              .foregroundColor(.accent)
              .cornerRadius(height / 2)
            
            if !isRounded {
              Rectangle()
                .frame(width: height, height: height)
                .foregroundColor(.accent)
            }
          },
          alignment: .leading
        )
    }.frame(height: height)
  }
}

struct ProgressBarView_Previews: PreviewProvider {
  static var previews: some View {
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
    .background(Color.background)
    .inAllColorSchemes
  }
}
