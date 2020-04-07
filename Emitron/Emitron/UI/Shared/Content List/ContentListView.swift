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

struct ContentListView: View {
  @State private var deleteSubscriptions = Set<AnyCancellable>()
  @ObservedObject var contentRepository: ContentRepository
  var downloadAction: DownloadAction
  var contentScreen: ContentScreen
  var headerView: AnyView?

  var body: some View {
    contentView
      .onAppear {
        UIApplication.dismissKeyboard()
        self.reloadIfRequired()
      }
  }

  private var contentView: AnyView {
    reloadIfRequired()
    switch contentRepository.state {
    case .initial:
      return AnyView(loadingView)
    case .loading:
      return AnyView(loadingView)
    case .loadingAdditional:
      return AnyView(listView)
    case .hasData where contentRepository.isEmpty:
      return AnyView(noResultsView)
    case .hasData:
      return AnyView(listView)
    case .failed:
      return AnyView(reloadView)
    }
  }
  
  private func reloadIfRequired() {
    if self.contentRepository.state == .initial {
      self.contentRepository.reload()
    }
  }

  private var cardsView: some View {
    ForEach(contentRepository.contents, id: \.id) { partialContent in
      ZStack {
        CardViewContainer(
          model: partialContent,
          dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: partialContent.id)
        )
        
        self.navLink(for: partialContent)
          .buttonStyle(PlainButtonStyle())
          //HACK: to remove navigation chevrons
          .padding(.trailing, -2 * .sidePadding)
      }
    }
      .if(allowDelete) { $0.onDelete(perform: self.delete) }
      .listRowInsets(EdgeInsets())
      .padding([.horizontal, .top], .sidePadding)
      .background(Color.backgroundColor)
  }
  
  private func navLink(for content: ContentListDisplayable) -> some View {
    NavigationLink(
      destination: ContentDetailView(
        content: content,
        childContentsViewModel: self.contentRepository.childContentsViewModel(for: content.id),
        dynamicContentViewModel: self.contentRepository.dynamicContentViewModel(for: content.id)
      )) {
      EmptyView()
    }
  }
  
  private var allowDelete: Bool {
    if case .downloads = contentScreen {
      return true
    }
    return false
  }
  
  private var listView: some View {
    List {
      if self.headerView != nil {
        Section(header: self.headerView) {
          self.cardsView
          self.loadMoreView
          // Hack to make sure there's some spacing at the bottom of the list
          Color.clear.frame(height: 0)
        }.listRowInsets(EdgeInsets())
      } else {
        self.cardsView
        self.loadMoreView
        // Hack to make sure there's some spacing at the bottom of the list
        Color.clear.frame(height: 0)
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
  
  private var loadingView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      
      VStack {
        headerView
        Spacer()
        LoadingView()
        Spacer()
      }
    }
  }
  
  private var noResultsView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      
      NoResultsView(
        contentScreen: contentScreen,
        headerView: headerView
      )
    }
  }
  
  private var reloadView: some View {
    ZStack {
      Color.backgroundColor.edgesIgnoringSafeArea(.all)
      
      ReloadView(headerView: headerView) {
        self.contentRepository.reload()
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

  private func delete(at offsets: IndexSet) {
    guard let index = offsets.first else {
      return
    }
    DispatchQueue.main.async {
      let content = self.contentRepository.contents[index]
      
      self.downloadAction
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
          MessageBus.current.post(message: Message(level: .success, message: Constants.downloadDeleted))
        }
        .store(in: &self.deleteSubscriptions)
    }
  }
}
