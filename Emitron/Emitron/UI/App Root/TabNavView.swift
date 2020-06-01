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

struct TabNavView: View {
  @EnvironmentObject var tabViewModel: TabViewModel
  var libraryView: AnyView
  var myTutorialsView: AnyView
  var downloadsView: AnyView

  var body: some View {
    TabView(selection: $tabViewModel.selectedTab) {
      NavigationView {
        libraryView
      }
        .tabItem {
          Text(Constants.library)
          Image("library")
        }
        .tag(MainTab.library)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: Text(Constants.library))

      NavigationView {
        downloadsView
      }
        .tabItem {
          Text(Constants.downloads)
          Image("downloadTabInactive")
        }
        .tag(MainTab.downloads)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: Text(Constants.downloads))

      NavigationView {
        myTutorialsView
      }
        .tabItem {
          Text(Constants.myTutorials)
          Image("myTutorials")
        }
        .tag(MainTab.myTutorials)
        .navigationViewStyle(StackNavigationViewStyle())
        .accessibility(label: Text(Constants.myTutorials))
    }
    .accentColor(.accent)
  }
}

struct TabNavView_Previews: PreviewProvider {
  static var previews: some View {
    TabNavView(
      libraryView: AnyView(Text("LIBRARY")),
      myTutorialsView: AnyView(Text("MY TUTORIALS")),
      downloadsView: AnyView(Text("DOWNLOADS"))
    ).environmentObject(TabViewModel())
  }
}
