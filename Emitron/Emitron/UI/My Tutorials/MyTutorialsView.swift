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
    NavigationView {
      contentView
      .background(Color.paleGrey)
      .navigationBarTitle(Text(Constants.myTutorials))
      .navigationBarItems(trailing:
        Button(action: {
          self.settingsPresented = true
        }) {
          HStack {
            Image("settings")
              .foregroundColor(.battleshipGrey)
              .sheet(isPresented: self.$settingsPresented) {
                SettingsView(isPresented: self.$settingsPresented)
            }
          }
        }
      )
    }
  }
  
  private var toggleControl: AnyView {
    AnyView(ToggleControlView(inProgressClosure: {
      self.state = .inProgress
    }, completedClosure: {
      self.state = .completed
    }, bookmarkedClosure: {
      self.state = .bookmarked
    })
      .padding([.top], .sidePadding)
      .background(Color.paleGrey)
    )
  }

  private var contentView: some View {
    let dataToDisplay: [ContentSummaryModel]

    switch state {
    case .inProgress, .completed:
      switch progressionsMC.state {
      case .initial,
           .loading where progressionsMC.data.isEmpty:
        return AnyView(Text(Constants.loading))
      case .failed:
        return AnyView(Text("Error"))
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

      default:
        return AnyView(Text("Default View"))
      }

    case .bookmarked:
      switch bookmarksMC.state {
      case .initial,
           .loading where bookmarksMC.data.isEmpty:
        return AnyView(Text(Constants.loading))
      case .failed:
        return AnyView(Text("Error"))
      case .hasData,
           .loading where !bookmarksMC.data.isEmpty:
        let content = bookmarksMC.data.compactMap { $0.content }
        dataToDisplay = content

      default:
        return AnyView(Text("Default View"))
      }
    }

    return AnyView(ContentListView(contentScreen: .myTutorials, contents: dataToDisplay, bgColor: .paleGrey, headerView: toggleControl))
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
