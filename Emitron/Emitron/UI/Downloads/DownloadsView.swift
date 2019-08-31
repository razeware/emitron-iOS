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

struct DownloadsView: View {
  @State var contentScreen: ContentScreen
  @EnvironmentObject var contentsMC: ContentsMC
  
  var body: some View {
    VStack {
      HStack {
        Text(Constants.downloads)
          .multilineTextAlignment(.leading)
          .font(.uiLargeTitle)
          .foregroundColor(.appBlack)
          .padding([.top, .leading], .sidePadding)
        
        Spacer()
      }
      
      Spacer()
      
      contentView()
        .padding([.top], .sidePadding)
        .background(Color.paleGrey)
      
      Spacer()
      
      addButton()
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
      //      let sorted = sortSelection.sorted(data: contentsMC.data)
      //      let parameters = filters.applied
      //      let filtered = sorted.filter { $0.domains.map { $0.id }.contains(domainIdInt) }
      //
      
      return AnyView(ContentListView(contentScreen: .downloads, contents: contentsMC.data, bgColor: .paleGrey))
    default:
      return AnyView(Text("Default View"))
    }
  }
  
  private func addButton() -> AnyView? {
    guard let buttonText = contentScreen.buttonText, let buttonColor = contentScreen.buttonColor, let buttonImage = contentScreen.buttonIconName else { return nil }
    
    // TODO use button Lea created in persistFilters PR once available
    let button = Button(action: {
      // TODO what is the action supposed to be here?
      print("BUTTON TAPPED IN DOWNLOADS VIEW")
      
    }) {
      HStack {
        Rectangle()
          .frame(width: 24, height: 46, alignment: .center)
          .foregroundColor(buttonColor)
        
        Spacer()
        
        Text(buttonText)
          .font(.uiButtonLabel)
          .background(buttonColor)
          .foregroundColor(.white)
        
        Spacer()
        
        Image(buttonImage)
          .frame(width: 24, height: 24, alignment: .center)
          .background(Color.white)
          .foregroundColor(buttonColor)
          .cornerRadius(6)
          .padding([.trailing], 10)
      }
      .background(buttonColor)
      .cornerRadius(6)
      .padding([.leading, .trailing], 18)
      .frame(height: 46)
    }
    
    return AnyView(button)
  }
}

#if DEBUG
struct DownloadsView_Previews: PreviewProvider {
  static var previews: some View {
    let contentsMC = DataManager.current.contentsMC
    return DownloadsView(contentScreen: .downloads).environmentObject(contentsMC)
  }
}
#endif
