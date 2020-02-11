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

private enum Layout {
  static let sidePadding: CGFloat = 18
  static let heightDivisor: CGFloat = 3
}

struct ContentListView: View {

  @State var showHudView: Bool = false
  @State var showAlert: Bool = false
  @State private var showSettings = false
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
      if self.headerView != nil {
        Section(header: self.headerView) {
          self.appropriateCardsView
          self.loadMoreView
        }.listRowInsets(EdgeInsets())
      } else {
        
        if self.contentRepository.isEmpty {
          AnyView(
            NoResultsView(
              contentScreen: self.contentScreen,
              headerView: self.headerView
            )
          )
        } else {
          self.appropriateCardsView
        }
        
        self.loadMoreView
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
        GeometryReader { _ in
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
        ZStack {
          listView
            .blur(radius: Constants.blurRadius)
          
          LoadingView()
        }
      )
    case .loadingAdditional:
      return AnyView(listView)
    case .hasData where contentRepository.isEmpty:
      return AnyView(
        NoResultsView(
          contentScreen: contentScreen,
          headerView: headerView
        )
      )
    case .hasData:
      return AnyView(listView)
    case .failed:
      return AnyView(ReloadView(headerView: headerView) {
        self.contentRepository.reload()
      })
    default:
      return AnyView(
        NoResultsView(
          contentScreen: contentScreen,
          headerView: headerView
        )
      )
    }
  }

  private var cardTableNavView: AnyView {
    AnyView(ForEach(contentRepository.contents, id: \.id) { partialContent in
      NavigationLink(destination: ContentDetailView(
        content: partialContent,
        childContentsViewModel: self.contentRepository.childContentsViewModel(for: partialContent.id),
        dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id))) {
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
        dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id))) {
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
  
  private var appropriateCardsView: AnyView {
    if case .downloads = contentScreen {
      return cardsTableViewWithDelete
    } else {
      return cardTableNavView
    }
  }
  
  private var loadingView: some View {
    ZStack {
      VStack {
        headerView
        Spacer()
      }
        .background(Color.backgroundColor)
        .blur(radius: Constants.blurRadius)
      
      LoadingView()
    }
  }

  func delete(at offsets: IndexSet) {
    guard let index = offsets.first else {
      return
    }
    DispatchQueue.main.async {
      let content = self.contentRepository.contents[index]
      
      do {
        try self.downloadAction.deleteDownload(contentId: content.id)
      } catch {
        Failure
          .downloadAction(from: String(describing: type(of: self)), reason: "Unable to perform download action: \(error)")
        .log()
      }
    }
  }
}
