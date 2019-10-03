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
  // It's fine that this child view isn't observing this parameter, because the parent is, so the changes will trickle down through the requests
  // Good thought to have when creating the architecture for non-networking based views
  var contentSummary: ContentDetailsModel
  var buttonAction: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: .horizontalSpacing) {
        
        doneCheckbox
        
        Text(contentSummary.name)
          .font(.uiHeadline)
          .fixedSize(horizontal: false, vertical: true)
        
        Spacer()
        
        //ISSUE: Should probably wrap this in a Button view, but the tapAction, when placed on a cell doesn't actually register for the button,
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
  
  private var doneCheckbox: AnyView {
    let numberView = ZStack {
      Rectangle()
        .frame(width: .buttonSide, height: .buttonSide, alignment: .center)
        .foregroundColor(.brightGrey)
        .cornerRadius(6)
      
      Text("\(contentSummary.index ?? 0)")
        .font(.uiButtonLabelSmall)
        .foregroundColor(.white)
    }
    .onTapGesture {
      self.toggleCompleteness()
    }
    
    let completeView = ZStack(alignment: .center) {
      Rectangle()
        .frame(width: .buttonSide, height: .buttonSide)
        .foregroundColor(Color.appGreen)
      
      Image("checkmark")
        .resizable()
        .frame(maxWidth: 15, maxHeight: 17)
        .foregroundColor(Color.white)
    }
    .cornerRadius(6)
    
    guard let progression = contentSummary.progression, progression.finished else {
      return AnyView(numberView)
    }
    return AnyView(completeView)
  }
  
  private func toggleCompleteness() {
    print("Make me complete!!!")
  }
}
