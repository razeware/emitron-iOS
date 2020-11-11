// Copyright (c) 2019 Razeware LLC
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
import Combine

struct ContentListView<Header: View> {
  init(
    contentRepository: ContentRepository,
    downloadAction: DownloadAction,
    contentScreen: ContentScreen,
    header: Header
  ) {
    self.contentRepository = contentRepository
    self.downloadAction = downloadAction
    self.contentScreen = contentScreen
    self.header = header
  }

  @ObservedObject private var contentRepository: ContentRepository
  private let downloadAction: DownloadAction
  private let contentScreen: ContentScreen
  private let header: Header

  @State private var deleteSubscriptions: Set<AnyCancellable> = []
}

// MARK: - View
extension ContentListView: View {
  var body: some View {
    contentView
      .onAppear {
        UIApplication.dismissKeyboard()
        reloadIfRequired()
      }
  }
}

// MARK: - private
private extension ContentListView {
  var contentView: some View {
    reloadIfRequired()

    @ViewBuilder var contentView: some View {
      switch contentRepository.state {
      case .initial, .loading:
        loadingView
      case .hasData where contentRepository.isEmpty:
        noResultsView
      case .hasData, .loadingAdditional:
        listView
      case .failed:
        reloadView
      }
    }

    return contentView
  }

  func reloadIfRequired() {
    if contentRepository.state == .initial {
      contentRepository.reload()
    }
  }

  var listContentView: some View {
    SwiftUI.Group {
      cardsView
      loadMoreView
      // Hack to make sure there's some spacing at the bottom of the list
      Color.backgroundColor
    }
  }

  var cardsView: some View {
    ForEach(contentRepository.contents, id: \.id) { partialContent in
      ZStack {
        CardViewContainer(
          model: partialContent,
          dynamicContentViewModel: contentRepository.dynamicContentViewModel(for: partialContent.id)
        )
        
        navLink(for: partialContent)
          .buttonStyle(PlainButtonStyle())
          //HACK: to remove navigation chevrons
          .padding(.trailing, -2 * .sidePadding)
      }
    }
    .if(allowDelete) { $0.onDelete(perform: delete) }
    .listRowInsets(EdgeInsets())
    .padding([.horizontal, .top], .sidePadding)
    .background(Color.backgroundColor)
  }
  
  func navLink(for content: ContentListDisplayable) -> some View {
    NavigationLink(
      destination: ContentDetailView(
        content: content,
        childContentsViewModel: contentRepository.childContentsViewModel(for: content.id),
        dynamicContentViewModel: contentRepository.dynamicContentViewModel(for: content.id)
      )) {
      EmptyView()
    }
  }
  
  var allowDelete: Bool {
    if case .downloads = contentScreen {
      return true
    }
    return false
  }
  
  var listView: some View {
    List {
      if #available(iOS 14, *) {
        makeSectionList {
          listContentView
        }
      } else {
        makeList {
          listContentView
        }
      }
    }
      .if(!allowDelete) {
        $0.gesture(
          DragGesture().onChanged { _ in
            UIApplication.dismissKeyboard()
          }
        )
      }
      .accessibility(identifier: "contentListView")
  }

  func makeList<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    Section(header: header, content: content)
      .listRowInsets(EdgeInsets())
  }

  @available(iOS 14, *)
  func makeSectionList<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    Section(header: header, content: content)
      .listRowInsets(EdgeInsets())
      .textCase(nil)
  }

  func makeList<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View where Header.Body == Never {
    content()
  }
  
  var loadingView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      
      VStack {
        header
        Spacer()
        LoadingView()
        Spacer()
      }
    }
  }
  
  var noResultsView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      
      NoResultsView(
        contentScreen: contentScreen,
        header: header
      )
    }
  }
  
  var reloadView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      ReloadView(header: header, reloadHandler: contentRepository.reload)
    }
  }
  
  @ViewBuilder var loadMoreView: some View {
    if contentRepository.totalContentNum > contentRepository.contents.count {
      // HACK: To put it in the middle we have to wrap it in Geometry Reader
      GeometryReader { _ in
        ActivityIndicator()
          .onAppear(perform: contentRepository.loadMore)
      }
    }
  }

  func delete(at offsets: IndexSet) {
    guard let index = offsets.first else {
      return
    }
    DispatchQueue.main.async {
      let content = contentRepository.contents[index]
      
      downloadAction
        .deleteDownload(contentId: content.id)
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
          if case .failure(let error) = completion {
            Failure
              .downloadAction(from: String(describing: type(of: self)), reason: "Unable to perform download action: \(error)")
              .log()
            MessageBus.current.post(message: Message(level: .error, message: error.localizedDescription))
          }
        }) { _ in
          MessageBus.current.post(message: Message(level: .success, message: .downloadDeleted))
        }
        .store(in: &deleteSubscriptions)
    }
  }
}

extension ContentListView where Header == Never? {
  init(
    contentRepository: ContentRepository,
    downloadAction: DownloadAction,
    contentScreen: ContentScreen
  ) {
    self.init(
      contentRepository: contentRepository,
      downloadAction: downloadAction,
      contentScreen: contentScreen,
      header: nil
    )
  }
}
