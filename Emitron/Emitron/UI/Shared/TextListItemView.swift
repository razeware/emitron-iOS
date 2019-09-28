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
  static let horizontalSpacing: CGFloat = 15
  static let buttonSide: CGFloat = 30
}

struct TextListItemView: View {
  var contentSummary: ContentSummaryModel
  var buttonAction: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: .horizontalSpacing) {
        ZStack {
          Rectangle()
            .frame(width: .buttonSide, height: .buttonSide, alignment: .center)
            .foregroundColor(.brightGrey)
            .cornerRadius(6)
          
          Text("\(contentSummary.index)")
            .font(.uiButtonLabelSmall)
            .foregroundColor(.white)
        }
        
        Text(contentSummary.name)
          .font(.uiHeadline)
          .fixedSize(horizontal: false, vertical: true)
        
        Spacer()
        
        //TODO: Should probably wrap this in a Button view, but the tapAction, when placed on a cell doesn't actually register for the button,
        // it just passes through; example below
        Image("downloadInactive")
          .foregroundColor(.coolGrey)
          .onTapGesture {
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
      Text(contentSummary.duration.timeFromSeconds)
        .font(.uiCaption)
        .padding([.leading], CGFloat.horizontalSpacing + CGFloat.buttonSide)
    }
  }
}

#if DEBUG
struct TextListItemView_Previews: PreviewProvider {
  static var previews: some View {
    let contentSummary = ContentSummaryModel.test
    
    return TextListItemView(contentSummary: contentSummary, buttonAction: {
      print("Testing")
    })
  }
}
#endif
