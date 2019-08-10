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
import Combine

private extension CGFloat {
  static let sidePadding: CGFloat = 18
}

enum MyTutorialsState: String {
  case inProgress, completed, bookmarked
}

struct MyTutorialsView: View {
  
  // FJ TODO: Add in green progress bar once can tell if tutorial is in progress..
  @EnvironmentObject var contentsMC: ContentsMC
  @State private var settingsPresented: Bool = false
  @State private var state: MyTutorialsState = .inProgress
  
  var body: some View {
    VStack {
      VStack {
        
        HStack {
          Text(Constants.myTutorials)
          .font(.uiLargeTitle)
          .foregroundColor(.appBlack)
          
          Spacer()
          
          Button(action: {
            self.settingsPresented.toggle()
          }) {
            HStack {
              Image("settings")
              .foregroundColor(.battleshipGrey)
                .sheet(isPresented: self.$settingsPresented) {
                SettingsView()
              }
            }
          }
        }
        .padding([.top], .sidePadding)
      }
      .padding([.leading, .trailing, .top], .sidePadding)
      
      ToggleControlView(inProgressClosure: {
        self.state = .inProgress
        
      }, completedClosure: {
        self.state = .completed
        
      }, bookmarkedClosure: {
        self.state = .bookmarked
        
      })
        .padding([.leading, .trailing, .top], .sidePadding)
        .background(Color.paleGrey)
      
      contentView()
        .padding([.top], .sidePadding)
        .background(Color.paleGrey)
      
    }
    .background(Color.paleGrey)
  }
  
  private func contentView() -> AnyView {
    switch contentsMC.state {
    case .initial,
         .loading where contentsMC.data.isEmpty:
      return AnyView(Text(Constants.loading))
    case .failed:
      return AnyView(Text("Error"))
    case .hasData,
         .loading where !contentsMC.data.isEmpty:

      let allData = contentsMC.data
      let dataToDisplay: [ContentDetailModel]
      
      switch state {
      case .inProgress:
        let inProgressData = allData.filter { model -> Bool in
          guard let progression = model.progression else {
            return false
          }
          
          return progression.percentComplete > 0 && !progression.finished
        }
        
        dataToDisplay = inProgressData
      
      case .completed:
        let completedData = allData.filter { $0.progression?.finished == true }
        dataToDisplay = completedData
        
      case .bookmarked:
        let bookmarkedData = allData.filter { $0.bookmark != nil }
        dataToDisplay = bookmarkedData
      }
      
      return AnyView(ContentListView(showProgressBar: true, contents: dataToDisplay, bgColor: .paleGrey))
    default:
      return AnyView(Text("Default View"))
    }
  }
}

#if DEBUG
struct MyTutorialsView_Previews: PreviewProvider {
  static var previews: some View {
    let guardpost = Guardpost.current
    return MyTutorialsView().environmentObject(ContentsMC(guardpost: guardpost))
  }
}
#endif
