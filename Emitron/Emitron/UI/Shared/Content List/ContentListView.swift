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

struct ContentListView: View {

  @State var showHudView: Bool = false
  @State var showAlert: Bool = false
  @State private var showSettings = false
  @State var hudOption: HudOption = .success
  @State var isPresenting: Bool = false
  
  @ObservedObject var contentRepository: ContentRepository
  var downloadAction: DownloadAction
  var contentScreen: ContentScreen
  var headerView: AnyView?

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

          if contentRepository.isEmpty {
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

  private func openSettings() {
    // open iPhone settings
    if let url = URL(string: UIApplication.openSettingsURLString) {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  private var loadMoreView: AnyView? {
    if contentRepository.totalContentNum > contentRepository.contents.count {
      return AnyView(
        // HACK: To put it in the middle we have to wrap it in Geometry Reader
        GeometryReader { geometry in
          ActivityIndicator()
            .onAppear {
              self.contentRepository.loadMore()
          }
        }
      )
    } else {
      return nil
    }
  }

  private var contentView: AnyView {
    
    switch contentRepository.state {
    case .initial:
      contentRepository.reload()
      return AnyView(loadingView)
    case .loading where contentRepository.isEmpty:
      return AnyView(loadingView)
    case .loading where !contentRepository.isEmpty:
      // ISSUE: If we're RE-loading but not loading more, show the activity indicator in the middle, because the loading spinner at the bottom is always shown
      // since that's what triggers the additional content load (because there's no good way of telling that we've scrolled to the bottom of the scroll view
      return AnyView(
        listView
          .overlay(ActivityIndicator())
      )
    case .loadingAdditional:
      return AnyView(listView)
    case .hasData where contentRepository.isEmpty:
      return AnyView(emptyView)
    case .hasData:
      return AnyView(listView)
    case .failed:
      return AnyView(failedView)
    default:
      return AnyView(emptyView)
    }
  }

  private var cardTableNavView: AnyView {
    AnyView(ForEach(contentRepository.contents, id: \.id) { partialContent in
      NavigationLink(destination: ContentDetailView(
        content: partialContent,
        childContentsViewModel: self.contentRepository.childContentsViewModel(for: partialContent.id),
        dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id)))
      {
        CardView(model: partialContent, dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id))
          .padding([.leading], 10)
          .padding([.top, .bottom], 10)
      }
    }
    .listRowBackground(Color.backgroundColor)
    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    .background(Color.backgroundColor)
      //HACK: to remove navigation chevrons
      .padding(.trailing, -38.0)
    )
  }

  //TODO: Definitely not the cleanest solution to have almost a duplicate of the above variable, but couldn't find a better one
  private var cardsTableViewWithDelete: AnyView {
    AnyView(ForEach(contentRepository.contents, id: \.id) { partialContent in
      NavigationLink(destination: ContentDetailView(
        content: partialContent,
        childContentsViewModel: self.contentRepository.childContentsViewModel(for: partialContent.id),
        dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id)))
      {
        CardView(model: partialContent, dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id))
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
    )
  }
  
  // ISSUE: To make the status bar the same color as the rest of thee backgrounds, we have to make all of the views into Lists
  private var failedView: some View {
    VStack {
      
      headerView
      
      Spacer()
      
      Image("emojiCrying")
        .padding([.bottom], 30)
      
      Text("Something went wrong.")
        .font(.uiTitle2)
        .foregroundColor(.titleText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing, .bottom], 20)
      
      Text("Please try again.")
        .font(.uiLabel)
        .foregroundColor(.contentText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing], 20)
      
      Spacer()
      
      reloadButton
        .padding([.leading, .trailing, .bottom], 20)
    }
    .background(Color.backgroundColor)
  }

  private var emptyView: some View {
    VStack {
      headerView

      Spacer()

      Image(contentScreen.emptyImageName)
        .padding([.bottom], 30)
        .padding([.top], 97)
      // Accounting for the size of the navbar on iPhone 8, to push down conttent, because
      // we're ignoring the safe area edges, so that the status bar can be the right color

      Text(contentScreen.titleMessage)
        .font(.uiTitle2)
        .foregroundColor(.titleText)
        .multilineTextAlignment(.center)
        .padding([.bottom], 20)
        .padding([.leading, .trailing], 55)

      Text(contentScreen.detailMesage)
        .font(.uiLabel)
        .foregroundColor(.contentText)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing], 55)

      Spacer()

      exploreButton
    }
    .background(Color.backgroundColor)
  }

  private var exploreButton: AnyView? {
    guard let buttonText = contentScreen.buttonText, contentRepository.contents.isEmpty && contentScreen != .library else { return nil }

    let button = MainButtonView(title: buttonText, type: .primary(withArrow: true)) {
      print("I DON'T UNDERSTAND THE POINT OF THIS BUTTON")
      //self.emitron.selectedTab = 0
    }
    .padding([.bottom, .leading, .trailing], 20)

    return AnyView(button)
  }
  
  private var loadingView: some View {
    VStack {
      headerView
      Spacer()
    }
    .background(Color.backgroundColor)
    .overlay(ActivityIndicator())
  }
  
  private var reloadButton: AnyView? {

    let button = MainButtonView(title: "Reload", type: .primary(withArrow: false)) {
      self.contentRepository.reload()
    }

    return AnyView(button)
  }

  func delete(at offsets: IndexSet) {
    guard let index = offsets.first else { return }
    DispatchQueue.main.async {
      let content = self.contentRepository.contents[index]
      
      self.downloadAction.deleteDownload(contentId: content.id)
    }
  }
}
