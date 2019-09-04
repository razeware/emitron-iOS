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

  @State private var selection = 0
  @EnvironmentObject var contentsMC: ContentsMC

  var body: some View {
    let tabs = TabView(selection: $selection) {

      libraryView()
        .tabItem {
          Text(Constants.library)
          Image("library")
        }
        .tag(0)

      NavigationView {
        DownloadsView()
      }
        .tabItem {
          Text(Constants.downloads)
          Image("downloadInactive")
        }
        .tag(1)

      myTutorialsView()
        .tabItem {
          Text(Constants.myTutorials)
          Image("myTutorials")
        }
        .tag(2)
    }

    return tabs
  }
  
  func libraryView() -> AnyView {
    let filters = DataManager.current!.filters
    return AnyView(LibraryView().environmentObject(filters))
  }
  
  func myTutorialsView() -> AnyView {

    //TODO: I don't think this needs contentsMC from gurdpost, or contentsMC at all
    let guardpost = Guardpost.current
    let filters = DataManager.current!.filters
    let contentsMC = ContentsMC(guardpost: guardpost, filters: filters)
    
    let progressionsMC = DataManager.current!.progressionsMC
    let bookmarksMC = DataManager.current!.bookmarksMC
    
    return AnyView(MyTutorialsView().environmentObject(contentsMC).environmentObject(progressionsMC).environmentObject(bookmarksMC))
  }
}

#if DEBUG
struct TabNavView_Previews: PreviewProvider {
  static var previews: some View {
    TabNavView()
  }
}
#endif
