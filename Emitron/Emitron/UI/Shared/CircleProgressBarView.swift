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

private struct Layout {
  static let line: CGFloat = 5.0
  static let frame: CGFloat = 19.0
  static let endProgress: CGFloat = 0.0
}

struct CircularProgressBar: View {
  
  @State var isCollection = false
  @State var progress: CGFloat
  @State var spinCircle = false
  
  var body: some View {
    Image("downloadLoading")
    .foregroundColor(Color.coolGrey)
    .overlay(circleOverlay)
    .onAppear {
      while self.progress > 0.0 {
        self.spinCircle = true
        return
      }
      
      self.spinCircle = false
    }
  }
  
  var circleOverlay: some View {
    return Circle()
      .trim(from: 0.0, to: spinCircle ? progress : Layout.endProgress)
      .stroke(Color.appGreen, lineWidth: Layout.line)
      .frame(width: Layout.frame, height: Layout.frame)
      // FJ FIX make progress UP not count down
      .rotationEffect(.degrees(-90), anchor: .center)
      .animation(Animation.easeIn(duration: spinCircle ? isCollection ? 60 : 30 : 0))
  }
}

struct CircularProgressIndicator_Previews: PreviewProvider {
  static var previews: some View {
    CircularProgressBar(progress: 0.0)
  }
}
