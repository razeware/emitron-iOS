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

struct TabNavView<
  LibraryView: View,
  MyTutorialsView: View,
  DownloadsView: View,
  SettingsView: View
>: View {
  @EnvironmentObject var tabViewModel: TabViewModel
  let libraryView: LibraryView
  let myTutorialsView: MyTutorialsView
  let downloadsView: DownloadsView
  let settingsView: SettingsView

  var body: some View {
    TabView(selection: $tabViewModel.selectedTab) {
      NavigationView {
        libraryView
      }
        .tabItem {
          Text(String.library)
          Image("library")
        }
        .tag(MainTab.library)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: Text(String.library))

      NavigationView {
        downloadsView
      }
        .tabItem {
          Text(String.downloads)
          Image("downloadTabInactive")
        }
        .tag(MainTab.downloads)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: Text(String.downloads))

      NavigationView { myTutorialsView }
        .tabItem {
          Text(String.myTutorials)
          Image("myTutorials")
        }
        .tag(MainTab.myTutorials)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: .init(String.myTutorials))
      
      NavigationView { settingsView }
        .tabItem {
          Text(String.settings)
          Image("settings")
        }
        .tag(MainTab.settings)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: .init(String.settings))
    }
    .accentColor(.accent)
  }
}

struct TabNavView_Previews: PreviewProvider {
  static var previews: some View {
    TabNavView(
      libraryView: Text("LIBRARY"),
      myTutorialsView: Text("MY TUTORIALS"),
      downloadsView: Text("DOWNLOADS"),
      settingsView: Text("SETTINGS")
    ).environmentObject(TabViewModel())
  }
}
