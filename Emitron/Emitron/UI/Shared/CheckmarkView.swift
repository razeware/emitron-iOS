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

//TODO: Refactor layout properties here

struct CheckmarkView: View {
  var isOn: Bool
  
  var outerSide: CGFloat = 20
  var innerSide: CGFloat = 16
  var outerRadius: CGFloat = 6
  var radiusRatio: CGFloat {
    return outerRadius / outerSide
  }
  
  var onChange: (Bool) -> Void
  
  var body: some View {
        
    Button(action: {
      self.onChange(!self.isOn)
    }) {
      if isOn {
        ZStack(alignment: .center) {
          Rectangle()
            .frame(maxWidth: 20, maxHeight: 20)
            .foregroundColor(Color.appGreen)
          
          Image("checkmark")
            .resizable()
            .frame(maxWidth: 15, maxHeight: 17)
            .foregroundColor(Color.white)
        }
        .cornerRadius(6)
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: outerRadius)
          .frame(maxWidth: outerSide, maxHeight: outerSide)
          .foregroundColor(Color.coolGrey)
          
          RoundedRectangle(cornerRadius: radiusRatio * innerSide)
          .frame(maxWidth: innerSide, maxHeight: innerSide)
          .foregroundColor(Color.white)
        }
      }
    }
  }
}

#if DEBUG
struct CheckmarkView_Previews: PreviewProvider {
  static var previews: some View {
    // TODO: No empty String
    CheckmarkView(isOn: false, onChange: { change in
      print("Changed to: \(change)")
    })
  }
}
#endif
