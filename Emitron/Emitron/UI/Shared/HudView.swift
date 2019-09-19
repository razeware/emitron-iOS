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

enum HudOption {
  case success, error
  
  var title: String {
    switch self {
    case .success: return "success".uppercased()
    case .error: return "error".uppercased()
    }
  }
  
  var detail: String {
    switch self {
    case .error: return "Failure".capitalized
    default: return ""
    }
  }
  
  var color: Color {
    switch self {
    case .success: return .appGreen
    case .error: return .copper
    }
  }
}

struct HudView: View {
  var option: HudOption
  var callback: (()->())?
  
  var body: some View {
    
      HStack(alignment: .center) {
        ZStack {
          Rectangle()
          .foregroundColor(Color.white)
          .cornerRadius(15)
          .padding([.top, .bottom], 10)

          Text(self.option.title)
          .foregroundColor(self.option.color)
        }
        .padding([.leading], 18)
        
        Text(self.option.detail)
          .foregroundColor(Color.white)
          .padding([.top, .bottom], 10)

        Spacer()
        
        Button(action: {
          self.dismiss()
        }) {
          Image("close")
            .padding([.trailing], 18)
            .foregroundColor(Color.white)
        }
      }
        .background(self.option.color)
        .frame(width: UIScreen.main.bounds.width, height: 54, alignment: .leading)
  }
  
  private func dismiss() {
    callback?()
  }
}

#if DEBUG
struct HudView_Previews: PreviewProvider {
  static var previews: some View {
    // TODO: No empty String
    return HudView(option: .success)
  }
}
#endif

