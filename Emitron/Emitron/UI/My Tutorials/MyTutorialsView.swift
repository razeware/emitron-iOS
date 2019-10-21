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

  @EnvironmentObject var domainsMC: DomainsMC
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
        ToggleControlView(toggleState: state, inProgressClosure: {
          self.state = .inProgress
          self.progressionsMC.loadContents()
        }, completedClosure: {
          self.state = .completed
          self.progressionsMC.loadContents()
        }, bookmarkedClosure: {
          self.state = .bookmarked
          self.bookmarksMC.loadContents()
        })
          .padding([.top], .sidePadding)
      }
      .padding([.leading, .trailing], 20)
      .background(Color.backgroundColor)
      .shadow(color: Color.shadowColor, radius: 1, x: 0, y: 2)
    )
  }

  private var contentView: some View {
    switch state {
    case .inProgress: return AnyView(inProgressContentsView)
    case .completed: return AnyView(completedContentsView)
    case .bookmarked: return AnyView(bookmarkedContentsView)
    }
  }

  private var inProgressContentsView: some View {
    let progressions = progressionsMC.data.filter {  $0.percentComplete > 0 && !$0.finished }
    let dataToDisplay = progressions.compactMap { $0.content }
    dataToDisplay.forEach { model in
      model.domains = domainsMC.data.filter { model.domainIDs.contains($0.id) }
    }

    return ContentListView(downloadsMC: DataManager.current!.downloadsMC, contentScreen: .myTutorials, contents: dataToDisplay, headerView: toggleControl, dataState: progressionsMC.state, totalContentNum: progressionsMC.numTutorials)
  }

  private var completedContentsView: some View {
    let progressions = progressionsMC.data.filter {  $0.finished }
    let dataToDisplay = progressions.compactMap { $0.content }
    dataToDisplay.forEach { model in
      model.domains = domainsMC.data.filter { model.domainIDs.contains($0.id) }
    }
    return ContentListView(downloadsMC: DataManager.current!.downloadsMC, contentScreen: .myTutorials, contents: dataToDisplay, headerView: toggleControl, dataState: progressionsMC.state, totalContentNum: progressionsMC.numTutorials)
  }

  private var bookmarkedContentsView: some View {
    let dataToDisplay = bookmarksMC.data.compactMap { $0.content }
    dataToDisplay.forEach { model in
      model.domains = domainsMC.data.filter { model.domainIDs.contains($0.id) }
    }
    return ContentListView(downloadsMC: DataManager.current!.downloadsMC, contentScreen: .myTutorials, contents: dataToDisplay, headerView: toggleControl, dataState: bookmarksMC.state, totalContentNum: bookmarksMC.numTutorials)
  }
}

#if DEBUG
struct MyTutorialsView_Previews: PreviewProvider {
  static var previews: some View {
    let progressionsMC = DataManager.current!.progressionsMC
    let bookmarksMC = DataManager.current!.bookmarksMC
    let domainsMC = DataManager.current!.domainsMC
    return MyTutorialView().environmentObject(progressionsMC).environmentObject(bookmarksMC).environmentObject(domainsMC)
  }
}
#endif
