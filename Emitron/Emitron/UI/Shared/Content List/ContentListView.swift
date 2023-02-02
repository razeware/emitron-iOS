// Copyright (c) 2022 Kodeco Inc

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
    downloadService: DownloadService,
    contentScreen: ContentScreen,
    header: Header
  ) {
    self.contentRepository = contentRepository
    self.downloadService = downloadService
    self.contentScreen = contentScreen
    self.header = header
  }

  @ObservedObject private var contentRepository: ContentRepository
  private let downloadService: DownloadService
  private let contentScreen: ContentScreen
  private let header: Header

  @EnvironmentObject private var messageBus: MessageBus
  @EnvironmentObject private var tabViewModel: TabViewModel
  @Environment(\.mainTab) private var mainTab
}

// MARK: - View
extension ContentListView: View {
  var body: some View {
    contentView
      .onAppear {
        tabViewModel.showingDetailView[mainTab] = false
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

  var cardsView: some View {
    ForEach(contentRepository.contents, id: \.id) { partialContent in
      ZStack {
        CardView(
          model: partialContent,
          dynamicContentViewModel: contentRepository.dynamicContentViewModel(for: partialContent.id)
        )

        NavigationLink(
          destination: ContentDetailView(
            content: partialContent,
            childContentsViewModel: contentRepository.childContentsViewModel(for: partialContent.id),
            dynamicContentViewModel: contentRepository.dynamicContentViewModel(for: partialContent.id)
          ).onAppear {
            tabViewModel.showingDetailView[mainTab] = true
          },
          // This EmptyView and the 0 opacity below are used for `label`
          // instead of the CardView, in order to hide navigation chevrons on the right.
          label: EmptyView.init
        )
        .opacity(0)
      }
    }
    .if(allowDelete) { $0.onDelete(perform: delete) }
    .padding([.horizontal], .sidePadding)
    .padding([.top], .topPadding)
    .background(Color.background)
  }
  
  var allowDelete: Bool {
    switch contentScreen {
    case .downloads:
      return true
    default:
      return false
    }
  }
  
  var listView: some View {
    List {
      Section(
        header: header
          .id(TabViewModel.ScrollToTopID(mainTab: mainTab, detail: false))
      ) {
        cardsView
        loadMoreView
      }
      .listRowInsets(.init())
      .listRowSeparator(.hidden)
      .textCase(nil)
    }
    .if(!allowDelete) {
      $0.gesture(
        DragGesture().onChanged { _ in
          UIApplication.dismissKeyboard()
        }
      )
    }
    .accessibility(identifier: "contentListView")
    .scrollContentBackground(.hidden)
    .background(Color.background)
  }

  var loadingView: some View {
    ZStack {
      Color.background.edgesIgnoringSafeArea(.all)
      
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
      Color.background.edgesIgnoringSafeArea(.all)
      
      NoResultsView(
        contentScreen: contentScreen,
        header: header
      )
    }
  }

  var reloadView: some View {
    ZStack {
      Color.background.edgesIgnoringSafeArea(.all)
      ErrorView(header: header, buttonAction: contentRepository.reload)
    }
  }

  @ViewBuilder var loadMoreView: some View {
    if contentRepository.totalContentNum > contentRepository.contents.count {
      HStack {
        Spacer()
        ProgressView().scaleEffect(1, anchor: .center)
        Spacer()
      }
      .padding()
      .background(Color.background.edgesIgnoringSafeArea(.all))
      .onAppear(perform: contentRepository.loadMore)
    }
  }

  func delete(at offsets: IndexSet) {
    guard let content = (offsets.first.map { contentRepository.contents[$0] }) else {
      return
    }

    Task { @MainActor in
      do {
        try await downloadService.deleteDownload(contentID: content.id)
        messageBus.post(message: Message(level: .success, message: .downloadDeleted))
      } catch {
        Failure
          .downloadAction(from: Self.self, reason: "Unable to perform download action: \(error)")
          .log()
        messageBus.post(message: Message(level: .error, message: error.localizedDescription))
      }
    }
  }
}

extension ContentListView where Header == Never? {
  init(
    contentRepository: ContentRepository,
    downloadService: DownloadService,
    contentScreen: ContentScreen
  ) {
    self.init(
      contentRepository: contentRepository,
      downloadService: downloadService,
      contentScreen: contentScreen,
      header: nil
    )
  }
}
