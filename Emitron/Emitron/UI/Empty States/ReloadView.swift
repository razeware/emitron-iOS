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

struct ReloadView<Header: View> {
  init(
    header: Header,
    reloadHandler: @escaping () -> Void
  ) {
    self.header = header
    self.reloadHandler = reloadHandler
  }

  private let header: Header
  private let reloadHandler: () -> Void
}

// MARK: - View {
extension ReloadView: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.backgroundColor)
        .edgesIgnoringSafeArea(.all)
      VStack {
        header
        Spacer()

        Image("emojiCrying")
          .padding(.bottom, 30)

        Text("Something went wrong.")
          .font(.uiTitle2)
          .foregroundColor(.titleText)
          .multilineTextAlignment(.center)
          .padding([.leading, .trailing, .bottom], 20)

        Text("Please try again.")
          .lineSpacing(8)
          .font(.uiLabel)
          .foregroundColor(.contentText)
          .multilineTextAlignment(.center)
          .padding([.leading, .trailing], 20)

        Spacer()

        MainButtonView(
          title: "Reload",
          type: .primary(withArrow: false),
          callback: reloadHandler)
          .padding([.horizontal, .bottom], 20)
      }
    }
  }
}

struct ErrorView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      ReloadView(header: EmptyView(), reloadHandler: {}).colorScheme(.light)
      ReloadView(header: EmptyView(), reloadHandler: {}).colorScheme(.dark)
    }
  }
}
