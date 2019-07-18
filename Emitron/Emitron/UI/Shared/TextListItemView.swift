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

struct TextListItemView: View {
  var contentSummary: ContentSummary?
  var timeStamp: String?
  var buttonAction: () -> ()
  
  //TODO: This should be coming from the BE eventually, but for now we're doing some magic transformation to get the correct title
  private var titleString: String {
    guard let name = contentSummary?.name else { return "No name :(" }
    
    let realTitle = name.split(separator: "·", maxSplits: 1, omittingEmptySubsequences: true)
    let str = "\(realTitle.last!)"
    return str.trimmingCharacters(in: .whitespaces)
  }
  
  var body: some View {
    HStack(alignment: .center, spacing: 15) {
      ZStack {
        Rectangle()
          .frame(width: 30, height: 30, alignment: .center)
          .foregroundColor(.brightGrey)
          .cornerRadius(6)
        
        Text("\(contentSummary?.index ?? 0)")
          .font(.uiButtonLabelSmall)
          .foregroundColor(.white)
      }
      
      VStack(alignment: .leading) {
        Text(titleString)
          .font(.uiHeadline)
          .lineLimit(nil)
        Text(timeStamp ?? "1:31")
          .font(.uiCaption)
      }
      
      Spacer()
      
      //TODO: Should probably wrap this in a Button view, but the tapAction, when placed on a cell doesn't actually register for the button,
      // it just passes through; example below
      Image("download")
        .foregroundColor(.coolGrey)
        .tapAction {
          self.buttonAction()
        }
      
//      Button(action: {
//        self.buttonAction()
//      }) {
//        Image("download")
//          .foregroundColor(.coolGrey)
//        }
//      }
    }
  }
}

#if DEBUG
struct TextListItemView_Previews: PreviewProvider {
  static var previews: some View {
    TextListItemView(contentSummary: nil, timeStamp: nil, buttonAction: {
      print("Testing")
    })
  }
}
#endif
