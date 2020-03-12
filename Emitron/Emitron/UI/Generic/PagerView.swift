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

struct PagerView<Content: View>: View {
  @State private var currentIndex: Int = 0
  @GestureState private var translation: CGFloat = 0
  
  let pageCount: Int
  let showIndicator: Bool
  let content: Content
  
  init(pageCount: Int, showIndicator: Bool = false, @ViewBuilder content: () -> Content) {
    self.pageCount = pageCount
    self.showIndicator = showIndicator
    self.content = content()
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      GeometryReader { proxy in
        HStack(spacing: 0) {
          self.content
            .frame(width: proxy.size.width)
        }
          .frame(width: proxy.size.width, alignment: .leading)
          .offset(x: -CGFloat(self.currentIndex) * proxy.size.width)
          .offset(x: self.translation)
        .animation(.interactiveSpring())
          .gesture(
            DragGesture()
              .updating(self.$translation) { value, state, _ in
                state = value.translation.width
              }
              .onEnded { value in
                let offset = value.translation.width / proxy.size.width
                if abs(offset) < 0.1 {
                  return
                }
                let newIndex = offset < 0 ? self.currentIndex + 1 : self.currentIndex - 1
                self.currentIndex = Int(newIndex).clamped(to: 0...(self.pageCount - 1))
              }
          )
      }
      
      if showIndicator {
        PagingIndicatorView(pageCount: pageCount, currentIndex: $currentIndex)
          .padding()
      }
    }
  }
}

#if DEBUG
struct PagerView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      PagerView(pageCount: 3) {
        Color.red
        Color.blue
        Color.green
      }
      
      PagerView(pageCount: 5, showIndicator: true) {
        Color.red
        Color.blue
        Color.green
        Color.yellow
        Color.purple
      }
    }
  }
}
#endif
