// Copyright (c) 2022 Razeware LLC
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

enum MyTutorialsState: String {
  case inProgress
  case bookmarked
  case completed
  
  var displayString: String {
    switch self {
    case .inProgress:
      return "In Progress"
    case .bookmarked:
      return "Bookmarks"
    case .completed:
      return "Completed"
    }
  }
}

// MARK: - CaseIterable
extension MyTutorialsState: CaseIterable {
  var index: Self.AllCases.Index {
    get {
      Self.allCases.firstIndex(of: self)!
    }
    set {
      self = Self.allCases[newValue]
    }
  }

  var count: Int {
    Self.allCases.count
  }
}

// MARK: - Identifiable
extension MyTutorialsState: Identifiable {
  var id: Self { self }
}

// MARK: -
struct MyTutorialsView {
  init(
    state: MyTutorialsState,
    inProgressRepository: InProgressRepository,
    completedRepository: CompletedRepository,
    bookmarkRepository: BookmarkRepository,
    domainRepository: DomainRepository
  ) {
    _state = .init(wrappedValue: state)
    self.inProgressRepository = inProgressRepository
    self.completedRepository = completedRepository
    self.bookmarkRepository = bookmarkRepository
    self.domainRepository = domainRepository
  }

  @EnvironmentObject private var downloadService: DownloadService
  @State private var state: MyTutorialsState
  
  private let inProgressRepository: InProgressRepository
  private let completedRepository: CompletedRepository
  private let bookmarkRepository: BookmarkRepository
  @ObservedObject private var domainRepository: DomainRepository

  @State private var settingsPresented = false
  @State private var reloadProgression = true
  @State private var reloadCompleted = true
  @State private var reloadBookmarks = true
}

// MARK: - View
extension MyTutorialsView: View {
  var body: some View {
    contentView
      .navigationTitle(String.myTutorials)
  }
}

// MARK: - private
private extension MyTutorialsView {
  @ViewBuilder var contentView: some View {
    switch state {
    case .inProgress:
      makeContentListView(
        contentRepository: inProgressRepository,
        contentScreen: .inProgress
      )
    case .bookmarked:
      makeContentListView(
        contentRepository: bookmarkRepository,
        contentScreen: .bookmarked
      )
    case .completed:
      makeContentListView(
        contentRepository: completedRepository,
        contentScreen: .completed
      )
    }
  }

  func makeContentListView(
    contentRepository: ContentRepository,
    contentScreen: ContentScreen
  ) -> some View {
    var toggleControl: some View {
      VStack {
        ToggleControlView(
          toggleState: state,
          toggleUpdated: { newState in
            state = newState
            switch newState {
            case .inProgress:
              // Should only call load contents if we have just switched to the My Tutorials tab
              if reloadProgression {
                inProgressRepository.reload()
                reloadProgression = false
              }
            case .bookmarked:
              if reloadBookmarks {
                bookmarkRepository.reload()
                reloadBookmarks = false
              }
            case .completed:
              if reloadCompleted {
                completedRepository.reload()
                reloadCompleted = false
              }
            }
          }
        )
          .padding(.top, .sidePadding)
      }
      .padding(.horizontal, .sidePadding)
      .background(Color.background)
    }
    
    return ContentListView(
      contentRepository: contentRepository,
      downloadAction: downloadService,
      contentScreen: contentScreen,
      header: toggleControl
    )
    .highPriorityGesture(DragGesture().onEnded({ handleSwipe(translation: $0.translation.width) }))
  }

  private func handleSwipe(translation: CGFloat) {
    if translation > .minDragTranslationForSwipe && state.index > 0 {
      state.index -= 1
    } else  if translation < -.minDragTranslationForSwipe && state.index < state.count - 1 {
      state.index += 1
    }
  }
}
