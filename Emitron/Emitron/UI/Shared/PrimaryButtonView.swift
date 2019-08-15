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

enum PrimaryButtonType {
  case `default`
  case destructive
  
  var color: Color {
    switch self {
    case .default:
      return .appGreen
    case .destructive:
      return .copper
    }
  }
  
  var arrowImage: UIImage {
    switch self {
    case .default:
      return #imageLiteral(resourceName: "arrowGreen")
    case .destructive:
      return #imageLiteral(resourceName: "arrowRed")
    }
  }
}

struct PrimaryButtonView: View {
  
  private var title: String
  private var type: PrimaryButtonType
  private var callback: () -> Void
  
  init(title: String, type: PrimaryButtonType, callback: @escaping () -> Void) {
    self.title = title
    self.type = type
    self.callback = callback
  }
  
  var body: some View {
    Button(action: {
      self.callback()
    }) {
      
      HStack {
        
        Rectangle()
          .frame(width: 24, height: 24, alignment: .center)
          .foregroundColor(type.color)
        
        Spacer()
        
        Text(title)
          .font(.uiButtonLabel)
          .background(type.color)
          .foregroundColor(.white)
        
        Spacer()
        
        Image(type.arrowImage)
          .resizable()
          .frame(width: 24, height: 24, alignment: .center)
          .background(Color.white)
          .foregroundColor(type.color)
          .cornerRadius(9)
          .padding([.trailing, .top, .bottom], 10)
      }
      .background(type.color)
      .cornerRadius(9)
    }
  }
}

#if DEBUG
struct MainButtonView_Previews: PreviewProvider {
  static var previews: some View {
    MainButtonView()
  }
}
#endif
