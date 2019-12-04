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
  
  @State var showActivityIndicator = false
  @State var contentScreen: ContentScreen
  @ObservedObject var downloadsMC: DownloadsMC

  var body: some View {
    ZStack(alignment: .center) {
      contentView
      .background(Color.backgroundColor)
      
      if showActivityIndicator {
        ActivityIndicator()
      }
    }
    .navigationBarTitle(Text(Constants.downloads))
    //.background(Color.backgroundColor) (If this is uncommented than the status bar becomes clear, and the large title doesn't become small)
  }

  private var contentView: some View {

    return ContentListView(downloadsMC: downloadsMC, contentsVM: downloadsMC as ContentPaginatable) { (action, content) in
      self.showActivityIndicator = true

      // need to get groups & child contents for collection
      if content.isInCollection {
        // DELETING
        // if an episode, don't need group & child contents
        if !self.downloadsMC.data.contains(where: { $0.parentContentId == content.parentContent?.id }) {
          self.handleAction(with: action, content: content)
        } else {
          // Handles deleting
          guard let user = Guardpost.current.currentUser else { return }
          let contentsMC = ContentsMC(user: user)
          contentsMC.getContentDetails(with: content.id) { contentDetails in
            guard let contentDetails = contentDetails else { return }
            self.handleAction(with: action, content: contentDetails)
          }
        }
      } else {
        self.handleAction(with: action, content: content)
      }
    }
  }

  private func handleAction(with action: DownloadsAction, content: ContentDetailsModel) {

    switch action {
    case .delete:
      if content.isInCollection {
        // if an episode, only delete the specific episode
        if !downloadsMC.downloadData.contains(where: { $0.content.parentContentId == content.parentContent?.id }) {
          downloadsMC.deleteDownload(with: content)
          self.showActivityIndicator = false
        } else {
          downloadsMC.deleteCollectionContents(withParent: content, showCallback: false)
          self.showActivityIndicator = false
        }
      } else {
        downloadsMC.deleteDownload(with: content)
        self.showActivityIndicator = false
      }

    case .save:
      self.downloadsMC.saveDownload(with: content, isEpisodeOnly: false)

    case .cancel:
      self.downloadsMC.cancelDownload(with: content, isEpisodeOnly: false)
    }
  }
}

#if DEBUG
struct DownloadsView_Previews: PreviewProvider {
  static var previews: some View {
    guard let dataManager = DataManager.current else { fatalError("dataManager is nil in DownloadsView") }
    let downloadsMC = dataManager.downloadsMC
    return DownloadsView(contentScreen: .downloads, downloadsMC: downloadsMC)
  }
}
#endif
