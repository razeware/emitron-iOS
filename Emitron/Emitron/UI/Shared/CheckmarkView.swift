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

struct CheckmarkView: View {
  @State private var isOn: Bool = false
  @EnvironmentObject var filters: Filters
  var filter: Filter
  
  var body: some View {
    
    Button(action: {
      self.filter.isOn.toggle()
      self.isOn = self.filter.isOn
      self.filters.filters.update(with: self.filter)
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
        Rectangle()
          .frame(maxWidth: 20, maxHeight: 20)
          .foregroundColor(Color.white)
          .cornerRadius(6)
          .border(Color.coolGrey, width: 2, cornerRadius: 6)
      }
    }
  }
}

#if DEBUG
struct CheckmarkView_Previews: PreviewProvider {
  static var previews: some View {
    // TODO: No empty String
    CheckmarkView(filter: Filter(groupType: .categories, param: Parameter(key: "bla", value: "bla", displayName: ""), isOn: false))
  }
}
#endif
