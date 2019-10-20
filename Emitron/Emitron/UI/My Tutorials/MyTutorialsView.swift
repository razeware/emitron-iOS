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

private extension CGFloat {
  static let sidePadding: CGFloat = 18
}

enum MyTutorialsState: String {
  case inProgress, completed, bookmarked
}

struct MyTutorialView: View {
  
  @EnvironmentObject var progressionsMC: ProgressionsMC
  @EnvironmentObject var bookmarksMC: BookmarksMC
  @State private var settingsPresented: Bool = false
  @State private var state: MyTutorialsState = .inProgress
  
  var body: some View {
    contentView
      .navigationBarTitle(Text(Constants.myTutorials))
      .navigationBarItems(trailing:
        Group {
          Button(action: {
            self.settingsPresented = true
          }) {
            Image("settings")
              .foregroundColor(.iconButton)
          }
      })
      .sheet(isPresented: self.$settingsPresented) {
        SettingsView(showLogoutButton: true)
      }
  }
  
  private var toggleControl: AnyView {
    AnyView(
      VStack {
        ToggleControlView(inProgressClosure: {
          self.state = .inProgress
        }, completedClosure: {
          self.state = .completed
        }, bookmarkedClosure: {
          self.state = .bookmarked
        })
          .padding([.top], .sidePadding)
      }
      .padding([.leading, .trailing], 20)
      .background(Color.backgroundColor)
      .shadow(color: Color.shadowColor, radius: 1, x: 0, y: 2)
    )
  }
  
  private var contentView: some View {
    var dataToDisplay: [ContentDetailsModel] = []
    var stateToUse: DataState
    var numTutorials: Int
    
    switch state {
    case .inProgress, .completed:
      stateToUse = progressionsMC.state
      numTutorials = progressionsMC.numTutorials
      
      switch progressionsMC.state {
      case .hasData,
           .loading where !progressionsMC.data.isEmpty:
        if state == .inProgress {
          let inProgressData = progressionsMC.data.filter { $0.percentComplete > 0 && !$0.finished }
          let contents = inProgressData.compactMap { $0.content }
          dataToDisplay = contents
        } else {
          let completedData = progressionsMC.data.filter { $0.finished == true }
          let contents = completedData.compactMap { $0.content }
          dataToDisplay = contents
        }
      default: break
      }
      
    case .bookmarked:
      stateToUse = bookmarksMC.state
      numTutorials = bookmarksMC.numTutorials
      
      switch bookmarksMC.state {
      case .hasData,
           .loading where !bookmarksMC.data.isEmpty:
        let content = bookmarksMC.data.compactMap { $0.content }
        dataToDisplay = content
      default: break
      }
    }
    
    let contentView = ContentListView(downloadsMC: DataManager.current!.downloadsMC, contentScreen: .myTutorials, contents: dataToDisplay, headerView: toggleControl, dataState: stateToUse, totalContentNum: numTutorials)
    
    return AnyView(contentView)
  }
}

#if DEBUG
struct MyTutorialsView_Previews: PreviewProvider {
  static var previews: some View {
    let progressionsMC = DataManager.current!.progressionsMC
    let bookmarksMC = DataManager.current!.bookmarksMC
    return MyTutorialView().environmentObject(progressionsMC).environmentObject(bookmarksMC)
  }
}
#endif
