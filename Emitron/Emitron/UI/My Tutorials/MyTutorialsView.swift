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

struct MyTutorialView: View {
  
  // Initialization
  @State var state: MyTutorialsState

  // We need to pull these in to pass them to the settings view. We don't actually use them here.
  // I think this is a bug.
  @EnvironmentObject var sessionController: SessionController
  @EnvironmentObject var tabViewModel: TabViewModel
  
  var inProgressRepository: InProgressRepository
  var completedRepository: CompletedRepository
  var bookmarkRepository: BookmarkRepository
  @ObservedObject var domainRepository: DomainRepository

  @State private var settingsPresented: Bool = false
  @State private var reloadProgression: Bool = true
  @State private var reloadCompleted: Bool = true
  @State private var reloadBookmarks: Bool = true

  var body: some View {
    contentView
      .navigationBarTitle(Text(Constants.myTutorials))
      .navigationBarItems(trailing:
        SwiftUI.Group {
          Button(action: {
            self.settingsPresented = true
          }) {
            Image("settings")
              .foregroundColor(.iconButton)
          }
        })
      .sheet(isPresented: self.$settingsPresented) {
        SettingsView(showLogoutButton: true)
          // We have to pass this cos the sheet is in a different view hierarchy, so doesn't 'inherit' it.
          .environmentObject(self.sessionController)
          .environmentObject(self.tabViewModel)
      }
    .onDisappear {
      self.reloadProgression = true
      self.reloadCompleted = true
      self.reloadBookmarks = true
    }
  }

  private var toggleControl: AnyView {
    AnyView(
      VStack {
        ToggleControlView(
          toggleState: state,
          toggleUpdated: { newState in
            self.state = newState
            switch newState {
            case .inProgress:
              // Should only call load contents if we have just switched to the My Tutorials tab
              if self.reloadProgression {
                self.inProgressRepository.reload()
                self.reloadProgression = false
              }
            case .completed:
              if self.reloadCompleted {
                self.completedRepository.reload()
                self.reloadCompleted = false
              }
            case .bookmarked:
              if self.reloadBookmarks {
                self.bookmarkRepository.reload()
                self.reloadBookmarks = false
              }
            }
          })
          .padding([.top], .sidePadding)
      }
        .padding([.horizontal], .sidePadding)
        .background(Color.backgroundColor)
    )
  }

  private var contentView: AnyView? {
    switch state {
    case .inProgress:
      return inProgressContentsView
    case .completed:
      return completedContentsView
    case .bookmarked:
      return bookmarkedContentsView
    }
  }

  private var inProgressContentsView: AnyView? {
    AnyView(ContentListView(contentRepository: inProgressRepository,
                            downloadAction: DownloadService.current,
                            contentScreen: ContentScreen.inProgress,
                            headerView: toggleControl))
  }
  
  private var completedContentsView: AnyView? {
    AnyView(ContentListView(contentRepository: completedRepository,
                            downloadAction: DownloadService.current,
                            contentScreen: .completed,
                            headerView: toggleControl))
  }
  
  private var bookmarkedContentsView: AnyView? {
    AnyView(ContentListView(contentRepository: bookmarkRepository,
                            downloadAction: DownloadService.current,
                            contentScreen: .bookmarked,
                            headerView: toggleControl))
  }
}
