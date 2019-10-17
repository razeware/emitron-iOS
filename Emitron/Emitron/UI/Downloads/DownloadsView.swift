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

private extension CGFloat {
  static let sidePadding: CGFloat = 18
}

struct DownloadsView: View {
  @State var contentScreen: ContentScreen
  @ObservedObject var downloadsMC: DownloadsMC
  @State var tabSelection: Int
  @EnvironmentObject var emitron: AppState
  var contents: [ContentDetailsModel] {
    return getContents()
  }

  var body: some View {
    VStack {
      contentView
      exploreButton
    }
    .navigationBarTitle(Text(Constants.downloads))
  }

  private var contentView: some View {
    ContentListView(downloadsMC: downloadsMC, contentScreen: .downloads, contents: contents, bgColor: .white, headerView: nil, dataState: downloadsMC.state, totalContentNum: downloadsMC.numTutorials) { (action, content) in
      self.handleAction(with: action, content: content)
    }
  }

  private func getContents() -> [ContentDetailsModel] {
    let downloadedContents = downloadsMC.data.map { $0.content }
    let parentContent = downloadedContents.filter { $0.contentType != .episode }
    return !parentContent.isEmpty ? parentContent : []
  }

  private func handleAction(with action: DownloadsAction, content: ContentDetailsModel) {

    switch action {
    case .delete:
      if content.isInCollection {
        downloadsMC.deleteCollectionContents(withParent: content, showCallback: false, completion: nil)
      } else {
        downloadsMC.deleteDownload(with: content)
      }

    case .save:
      self.downloadsMC.saveDownload(with: content)

    case .cancel:
      self.downloadsMC.cancelDownload(with: content)
    }
  }

  private var exploreButton: AnyView? {
    guard downloadsMC.data.isEmpty, let buttonText = contentScreen.buttonText else { return nil }

    let button = MainButtonView(title: buttonText, type: .primary(withArrow: true)) {
      self.emitron.selectedTab = 0
    }
    .padding([.bottom, .leading, .trailing], 20)

    return AnyView(button)
  }
}

#if DEBUG
struct DownloadsView_Previews: PreviewProvider {
  static var previews: some View {
    guard let dataManager = DataManager.current else { fatalError("dataManager is nil in DownloadsView") }
    let downloadsMC = dataManager.downloadsMC
    return DownloadsView(contentScreen: .downloads, downloadsMC: downloadsMC, tabSelection: 0)
  }
}
#endif
