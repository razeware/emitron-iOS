// Copyright (c) 2022 Razeware LLC
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

struct ErrorView<Header: View> {
  private let header: Header
  private let titleText = "Something went wrong."
  private let bodyText = "Please try again."
  private let buttonTitle: String
  private let buttonAction: () -> Void
}

// MARK: - internal
extension ErrorView {
  init(
    header: Header,
    buttonAction: @escaping () -> Void
  ) {
    self.init(
      header: header,
      buttonTitle: "Reload",
      buttonAction: buttonAction
    )
  }
}

extension ErrorView where Header == EmptyView {
  init(
    buttonTitle: String,
    buttonAction: @escaping () -> Void
  ) {
    self.init(
      header: .init(),
      buttonTitle: buttonTitle,
      buttonAction: buttonAction
    )
  }
}

// MARK: - View {
extension ErrorView: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.background)
        .edgesIgnoringSafeArea(.all)
      VStack {
        header
        Spacer()

        Image("Error")
          .padding(.bottom, 30)

        Text(titleText)
          .font(.uiTitle2)
          .foregroundColor(.titleText)
          .multilineTextAlignment(.center)
          .padding([.horizontal, .bottom], 20)

        Text(bodyText)
          .lineSpacing(8)
          .font(.uiLabel)
          .foregroundColor(.contentText)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 20)

        Spacer()

        MainButtonView(
          title: buttonTitle,
          type: .primary(withArrow: false),
          callback: buttonAction)
          .padding([.horizontal, .bottom], 20)
      }
    }
  }
}

struct ErrorView_Previews: PreviewProvider {
  static var previews: some View {
    ErrorView().inAllColorSchemes
  }
}

private extension ErrorView where Header == EmptyView {
  init() {
    self.init(header: .init()) { }
  }
}
