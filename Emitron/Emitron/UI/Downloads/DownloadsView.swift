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
  @EnvironmentObject var downloadsMC: DownloadsMC
  @State var showHudView: Bool = false
  @State var showSuccess: Bool = false
  @State var tabSelection: Int
  @EnvironmentObject var emitron: AppState
  var contents: [ContentSummaryModel] {
    return downloadsMC.data.map { $0.content }
  }

  var body: some View {
    VStack {
      HStack {
        Text(Constants.downloads)
          .multilineTextAlignment(.leading)
          .font(.uiLargeTitle)
          .foregroundColor(.appBlack)
          .padding([.top, .leading], .sidePadding)

        Spacer()
      }

      contentView()
        .padding([.top], .sidePadding)
        .background(Color.paleGrey)

      addButton()
    }
    .background(Color.paleGrey)
  }

  private func contentView() -> some View {
    switch downloadsMC.state {
    case .failed:
      fatalError("crash in DownloadsView with data")
    case .loading, .hasData, .initial:
      var updatedContents = contents
      var contentListView = ContentListView(contentScreen: .downloads, contents: updatedContents, bgColor: .paleGrey) { (action, content) in
        self.handleAction(with: action, content: content) { contents in
          self.downloadsMC.setDownloads(for: contents) { contents in
            updatedContents = contents
          }
        }
      }
      
      DispatchQueue.main.async {
        contentListView.updateContents(with: updatedContents)
      }
      
      if updatedContents.isEmpty {
        return ContentListView(contentScreen: .downloads, bgColor: .paleGrey)
      } else {
        return contentListView
      }
    }
  }
  
  private func handleAction(with action: DownloadsAction, content: ContentSummaryModel, completion: @escaping (([ContentSummaryModel])->())) {
    
    switch action {
    case .delete:
      self.downloadsMC.deleteDownload(with: content.videoID) { (success, contents) in
        self.showHudView.toggle()
        self.showSuccess = success
        if success {
          DispatchQueue.main.async {
            completion(contents)
          }
        }
      }
      
    case .save:
      self.downloadsMC.saveDownload(with: content) { (success, contents) in
        self.showHudView.toggle()
        self.showSuccess = success
        if success {
          DispatchQueue.main.async {
            completion(contents)
          }
        }
      }
    }
  }

  private func addButton() -> AnyView? {
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
    return DownloadsView(contentScreen: .downloads, tabSelection: 0).environmentObject(downloadsMC)
  }
}
#endif
