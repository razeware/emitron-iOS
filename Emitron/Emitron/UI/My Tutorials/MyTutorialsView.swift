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

enum MyTutorialsState: String {
  case inProgress
  case completed
  case bookmarked
  
  var contentScreen: ContentScreen {
    switch self {
    case .inProgress:
      return .inProgress
    case .completed:
      return .completed
    case .bookmarked:
      return .bookmarked
    }
  }
  
  var displayString: String {
    switch self {
    case .inProgress:
      return "In Progress"
    case .completed:
      return "Completed"
    case .bookmarked:
      return "Bookmarks"
    }
  }
}

struct MyTutorialView {
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

  // Initialization
  @State private var state: MyTutorialsState

  // We need to pull these in to pass them to the settings view. We don't actually use them here.
  // I think this is a bug.
  @EnvironmentObject private var sessionController: SessionController
  @EnvironmentObject private var tabViewModel: TabViewModel
  
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
extension MyTutorialView: View {
  var body: some View {
    contentView
      .navigationBarTitle(String.myTutorials)
      .navigationBarItems(trailing:
        SwiftUI.Group {
          Button(action: {
            settingsPresented = true
          }) {
            Image("settings")
              .foregroundColor(.iconButton)
          }
        })
      .sheet(isPresented: $settingsPresented) {
        SettingsView(showLogoutButton: true)
          // We have to pass this cos the sheet is in a different view hierarchy, so doesn't 'inherit' it.
          .environmentObject(sessionController)
          .environmentObject(tabViewModel)
      }
    .onDisappear {
      reloadProgression = true
      reloadCompleted = true
      reloadBookmarks = true
    }
  }
}

// MARK: - private
private extension MyTutorialView {
  @ViewBuilder var contentView: some View {
    switch state {
    case .inProgress:
      makeContentListView(
        contentRepository: inProgressRepository,
        contentScreen: .inProgress
      )
    case .completed:
      makeContentListView(
        contentRepository: completedRepository,
        contentScreen: .completed
      )
    case .bookmarked:
      makeContentListView(
        contentRepository: bookmarkRepository,
        contentScreen: .bookmarked
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
            case .completed:
              if reloadCompleted {
                completedRepository.reload()
                reloadCompleted = false
              }
            case .bookmarked:
              if reloadBookmarks {
                bookmarkRepository.reload()
                reloadBookmarks = false
              }
            }
          })
          .padding(.top, .sidePadding)
      }
      .padding(.horizontal, .sidePadding)
      .background(Color.backgroundColor)
    }
    
    return ContentListView(
      contentRepository: contentRepository,
      downloadAction: DownloadService.current,
      contentScreen: ContentScreen.inProgress,
      header: toggleControl
    )
  }
}
