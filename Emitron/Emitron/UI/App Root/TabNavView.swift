// Copyright (c) 2021 Razeware LLC
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

struct TabNavView<
  LibraryView: View,
  DownloadsView: View,
  MyTutorialsView: View,
  SettingsView: View
> {
  init(
    libraryView: @escaping () -> LibraryView,
    myTutorialsView: @escaping () -> MyTutorialsView,
    downloadsView: @escaping () -> DownloadsView,
    settingsView: @escaping () -> SettingsView
  ) {
    self.libraryView = libraryView
    self.myTutorialsView = myTutorialsView
    self.downloadsView = downloadsView
    self.settingsView = settingsView

    // Without the following, in iOS 15, this ugliness occurs:
    //
    // The nav bar renders as a rectangle that does not extend vertically past the safe area.
    // Scrolling content is visible above it.
    //
    // The tab bar renders transparently, on top of other views.
    if #available(iOS 15.0, *) {
      let barAppearance = UIBarAppearance()
      barAppearance.configureWithOpaqueBackground()
      UINavigationBar.appearance().scrollEdgeAppearance = .init(barAppearance: barAppearance)
      UITabBar.appearance().scrollEdgeAppearance = .init(barAppearance: barAppearance)
    }
  }

  @EnvironmentObject private var model: TabViewModel
  @EnvironmentObject private var settingsManager: SettingsManager

  private let libraryView: () -> LibraryView
  private let myTutorialsView: () -> MyTutorialsView
  private let downloadsView: () -> DownloadsView
  private let settingsView: () -> SettingsView
}

// MARK: - View
extension TabNavView: View {
  var body: some View {
    TabView(selection: $model.selectedTab) {
      tab(
        content: libraryView,
        text: .library,
        imageName: "library",
        tag: .library
      )

      tab(
        content: downloadsView,
        text: .downloads,
        imageName: "downloadTabInactive",
        tag: .downloads
      )

      tab(
        content: myTutorialsView,
        text: .myTutorials,
        imageName: "myTutorials",
        tag: .myTutorials
      )

      tab(
        content: settingsView,
        text: .settings,
        imageName: "settings",
        tag: .settings
      )
    }
    .accentColor(.accent)
  }
}

private func tab<Content: View>(
  content: () -> Content,
  text: String,
  imageName: String,
  tag: MainTab
) -> some View {
  NavigationView(content: content)
    .tabItem {
      Text(text)
      Image(imageName)
    }
    .tag(tag)
    .navigationViewStyle(StackNavigationViewStyle())
    .accessibility(label: .init(text))
}

struct TabNavView_Previews: PreviewProvider {
  static var previews: some View {
    TabNavView(
      libraryView: { Text("LIBRARY") },
      myTutorialsView: { Text("MY TUTORIALS") },
      downloadsView: { Text("DOWNLOADS") },
      settingsView: { Text("SETTINGS") }
    ).environmentObject(TabViewModel())
  }
}
