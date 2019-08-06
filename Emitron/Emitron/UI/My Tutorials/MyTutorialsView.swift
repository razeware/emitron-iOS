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

struct MyTutorialsView: View {
  
  // FJ TODO: Make sure data for my tutorials is from ContentsMC & find out requirements for sorting...
  @EnvironmentObject var contentsMC: ContentsMC
  
  var body: some View {
    VStack {
      VStack {
        
        HStack {
          Text(Constants.myTutorials)
          .font(.uiLargeTitle)
          .foregroundColor(.appBlack)
          
          Spacer()
          
          Button(action: {
            // Select settings
            self.selectSettings()
          }) {
            HStack {
              Image("settings")
                .foregroundColor(.battleshipGrey)
            }
          }
        }
        .padding([.top], .sidePadding)
      }
      .padding([.leading, .trailing, .top], .sidePadding)
      
      ToggleControlView()
        .padding([.top, .leading, .trailing], .sidePadding)
        .background(Color.paleGrey)
      
      contentView()
        .padding([.top], .sidePadding)
        .background(Color.paleGrey)
      
    }
    .background(Color.paleGrey)
  }
  
  private func selectSettings() {
    print("Settings tapped!")
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

      return AnyView(ContentListView(contents: contentsMC.data, bgColor: .paleGrey))
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
