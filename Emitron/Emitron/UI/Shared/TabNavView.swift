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

struct TabNavView: View {
  
  @State var selection = 0
  @EnvironmentObject var emitron: AppState
  @EnvironmentObject var contentsMC: ContentsMC
  
  var body: some View {
    TabView(selection: $emitron.selectedTab) {
      NavigationView {
        libraryView
      }.tabItem {
        Text(Constants.library)
        Image("library")
      }
      .tag(0)
      
      NavigationView {
        downloadsView
      }.tabItem {
        Text(Constants.downloads)
        Image("downloadInactive")
      }
      .tag(1)
      
      NavigationView {
        myTutorialsView
        
      }.tabItem {
        Text(Constants.myTutorials)
        Image("myTutorials")
      }
      .tag(2)
    }.edgesIgnoringSafeArea(.top)
  }
  
  private var libraryView: some View {
    guard let dataManager = DataManager.current else { fatalError("Data manager is nil in tabNavView") }
    let contentsMC = dataManager.contentsMC
    let downloadsMC = dataManager.downloadsMC
    let filters = dataManager.filters
    return LibraryView().environmentObject(contentsMC).environmentObject(downloadsMC).environmentObject(filters)
  }
  
  private var myTutorialsView: some View {
    guard let dataManager = DataManager.current else { fatalError("Data manager is nil in tabNavView") }
    let progressionsMC = dataManager.progressionsMC
    let bookmarksMC = dataManager.bookmarksMC
    return MyTutorialView().environmentObject(progressionsMC).environmentObject(bookmarksMC)
  }
  
  private var downloadsView: some View {
    guard let dataManager = DataManager.current else { fatalError("Data manager is nil in tabNavView") }
    let downloadsMC = dataManager.downloadsMC
    return DownloadsView(contentScreen: .downloads, tabSelection: selection).environmentObject(downloadsMC)
  }
}

#if DEBUG
struct TabNavView_Previews: PreviewProvider {
  static var previews: some View {
    TabNavView()
  }
}
#endif
