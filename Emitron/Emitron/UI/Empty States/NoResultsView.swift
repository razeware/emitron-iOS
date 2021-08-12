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

struct NoResultsView<Header: View> {
  init(
    contentScreen: ContentScreen,
    header: Header
  ) {
    self.contentScreen = contentScreen
    self.header = header
  }

  @EnvironmentObject private var tabViewModel: TabViewModel

  private let contentScreen: ContentScreen
  private let header: Header
}

// MARK: - View
extension NoResultsView: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.backgroundColor)
        .edgesIgnoringSafeArea(.all)
      VStack {
        header

        Spacer()

        Image(contentScreen.emptyImageName)
          .padding([.bottom], 30)

        Text(contentScreen.titleMessage)
          .font(.uiTitle2)
          .foregroundColor(.titleText)
          .multilineTextAlignment(.center)
          .padding([.bottom], 20)
          .padding([.leading, .trailing], 20)

        Text(contentScreen.detailMesage)
          .lineSpacing(5)
          .font(.uiLabel)
          .foregroundColor(.contentText)
          .multilineTextAlignment(.center)
          .padding([.bottom], 20)
          .padding([.leading, .trailing], 20)

        Spacer()

        if contentScreen.showExploreButton {
          MainButtonView(
            title: "Explore Tutorials",
            type: .primary(withArrow: true)) {
              tabViewModel.selectedTab = .library
          }
          .padding([.horizontal, .bottom], 20)
        }
      }
    }
  }
}

struct NoResultsView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      NoResultsView(contentScreen: .bookmarked).colorScheme(.light)
      NoResultsView(contentScreen: .bookmarked).colorScheme(.dark)
      NoResultsView(contentScreen: .completed).colorScheme(.light)
      NoResultsView(contentScreen: .completed).colorScheme(.dark)
      NoResultsView(contentScreen: .downloads(permitted: true)).colorScheme(.light)
      NoResultsView(contentScreen: .downloads(permitted: true)).colorScheme(.dark)
      NoResultsView(contentScreen: .downloads(permitted: false)).colorScheme(.light)
      NoResultsView(contentScreen: .downloads(permitted: false)).colorScheme(.dark)
      NoResultsView(contentScreen: .inProgress).colorScheme(.light)
      NoResultsView(contentScreen: .inProgress).colorScheme(.dark)
    }
    NoResultsView(contentScreen: .library).colorScheme(.light)
    NoResultsView(contentScreen: .library).colorScheme(.dark)
  }
}

// MARK: - private
private extension NoResultsView where Header == EmptyView {
  init(contentScreen: ContentScreen) {
    self.contentScreen = contentScreen
    header = .init()
  }
}
