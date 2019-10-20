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
  static let sidePadding: CGFloat = 18
  static let heightDivisor: CGFloat = 3
}

enum ContentScreen {
  case library, downloads, myTutorials, tips

  var titleMessage: String {
    switch self {
    // TODO: maybe this should be a func instead & we can pass in the actual search criteria here
    case .library: return "We couldn't find anything meeting the search criteria."
    case .downloads: return "You haven't downloaded any tutorials yet."
    case .myTutorials: return "You haven't started any tutorials yet."
    case .tips: return "Swipe left to delete a download."
    }
  }

  var detailMesage: String? {
    switch self {
    case .library: return "Try removing some filters or checking your \n WiFi settings."
    case .tips: return "Swipe on your downloads to remove them."
    default: return nil
    }
  }

  var buttonText: String? {
    switch self {
    case .downloads: return "Explore Tutorials"
    case .tips: return "Got it!"
    default: return "Reload"
    }
  }

  var buttonIconName: String? {
    switch self {
    case .downloads, .tips: return "arrowGreen"
    case .myTutorials: return "arrowRed"
    default: return nil
    }
  }

  var buttonColor: Color? {
    switch self {
    case .downloads, .tips: return .accent
    case .myTutorials: return .alarm
    default: return nil
    }
  }
}

struct ContentListView: View {

  var downloadsMC: DownloadsMC
  @State var contentScreen: ContentScreen
  @State var isPresenting: Bool = false
  var contents: [ContentDetailsModel] = []
  @State var selectedMC: ContentSummaryMC?
  @EnvironmentObject var contentsMC: ContentsMC
  var headerView: AnyView?
  var dataState: DataState
  var totalContentNum: Int
  var callback: ((DownloadsAction, ContentDetailsModel) -> Void)?

  var body: some View {
    contentView
      // ISSUE: If the below line gets uncommented, then the large title never changes to the inline one on scroll :(
      //.background(Color.backgroundColor)
  }

  private var listView: some View {
    List {
      if headerView != nil {
        Section(header: headerView) {
          if contentScreen == .downloads {
            cardsTableViewWithDelete
          } else {
            cardTableNavView
          }
          loadMoreView
        }.listRowInsets(EdgeInsets())
      } else {
        if contentScreen == .downloads {

          if contents.isEmpty || downloadsMC.data.isEmpty {
            emptyView
          } else {
            cardsTableViewWithDelete
          }

        } else {
          cardTableNavView
        }
        loadMoreView
      }
    }
  }

  private var loadMoreView: AnyView? {
    if totalContentNum > contents.count {
      return AnyView(
        // HACK: To put it in the middle we have to wrap it in Geometry Reader
        GeometryReader { geometry in
          ActivityIndicator()
            .onAppear {
              self.contentsMC.loadMore()
          }
        }
      )
    } else {
      return nil
    }
  }

  private var contentView: AnyView {
    switch dataState {
    case .initial,
         .loading where contents.isEmpty:
      return AnyView(loadingView)
    case .hasData where contents.isEmpty:
      return AnyView(emptyView)
    case .hasData,
         .loading where !contents.isEmpty:
      return AnyView(listView)
    case .failed:
      return AnyView(failedView)
    default:
      return AnyView(emptyView)
    }
  }

  private var failedView: some View {
    VStack {
      headerView

      Spacer()

      Text("Something went wrong.")
        .font(.uiTitle2)
        .foregroundColor(.titleText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing, .bottom], 20)

      Text("Please try again.")
        .font(.uiLabelBold)
        .foregroundColor(.contentText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing], 20)

      Spacer()

      reloadButton
        .padding([.leading, .trailing, .bottom], 20)
    }
  }

  private var cardTableNavView: some View {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser

    return
      ForEach(contents, id: \.id) { partialContent in

        NavigationLink(destination:
          ContentListingView(content: partialContent, user: user!, downloadsMC: self.downloadsMC))
        {
          self.cardView(content: partialContent, onLeftTap: { success in
            if success {
              self.callback?(.save, partialContent)
            }
          }, onRightTap: {
            // ISSUE: Removing bookmark functionality from the card for the moment, it only shows if the content is bookmarked and can't be acted upon
            //self.toggleBookmark(model: partialContent)
          })
            .padding([.leading], 10)
            .padding([.top, .bottom], 10)
        }
      }
      .listRowBackground(Color.backgroundColor)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .background(Color.backgroundColor)
      //HACK: to remove navigation chevrons
      .padding(.trailing, -38.0)
  }

  //TODO: Definitely not the cleanest solution to have almost a duplicate of the above variable, but couldn't find a better one
  private var cardsTableViewWithDelete: some View {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser

    return
      ForEach(contents, id: \.id) { partialContent in

        NavigationLink(destination:
          ContentListingView(content: partialContent, user: user!, downloadsMC: self.downloadsMC))
        {
          self.cardView(content: partialContent, onLeftTap: { success in
            if success {
              self.callback?(.save, partialContent)
            }
          }, onRightTap: {
            self.toggleBookmark(model: partialContent)
          })
            .padding([.leading], 10)
            .padding([.top, .bottom], 10)
        }
      }
      .onDelete(perform: self.delete)
      .listRowBackground(Color.backgroundColor)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .background(Color.backgroundColor)
      //HACK: to remove navigation chevrons
      .padding(.trailing, -38.0)
  }

  private func cardView(content: ContentDetailsModel, onLeftTap: ((Bool) -> Void)?, onRightTap: (() -> Void)?) -> AnyView? {
    AnyView(CardView(model: content,
                     contentScreen: contentScreen,
                     onLeftIconTap: onLeftTap,
                     onRightIconTap: onRightTap).environmentObject(self.downloadsMC))
  }

  private var emptyView: some View {
    VStack {
      headerView

      Spacer()

      Text(contentScreen.titleMessage)
        .font(.uiTitle2)
        .foregroundColor(.titleText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing, .bottom], 20)

      Text(contentScreen.detailMesage ?? "")
        .font(.uiLabelBold)
        .foregroundColor(.contentText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing], 20)

      Spacer()
    }
  }

  private var loadingView: some View {
    VStack {
      headerView
      Spacer()
    }
    .overlay(ActivityIndicator())
  }

  private var reloadButton: AnyView? {

    let button = MainButtonView(title: "Reload", type: .primary(withArrow: false)) {
      self.contentsMC.reloadContents()
    }

    return AnyView(button)
  }

  private func loadMoreContents() {
    contentsMC.loadMore()
  }

  func delete(at offsets: IndexSet) {
    guard let index = offsets.first else { return }
    DispatchQueue.main.async {
      let content = self.contents[index]
      self.callback?(.delete, content)
    }
  }

  mutating func updateContents(with newContents: [ContentDetailsModel]) {
    self.contents = newContents
  }

  func toggleBookmark(model: ContentDetailsModel) {
    DataManager.current?.contentsMC.toggleBookmark(for: model)
  }
}

#if DEBUG
struct ContentListView_Previews: PreviewProvider {
  static var previews: some View {
    return ContentListView(downloadsMC: DataManager.current!.downloadsMC, contentScreen: .library, contents: [], dataState: .hasData, totalContentNum: 5)
  }
}
#endif
