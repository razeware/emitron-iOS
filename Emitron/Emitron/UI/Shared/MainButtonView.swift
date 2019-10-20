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

enum MainButtonType {
  case primary(withArrow: Bool)
  case secondary(withArrow: Bool)
  case destructive(withArrow: Bool)
  
  var color: Color {
    switch self {
    case .primary:
      return .primaryButtonBackground
    case .secondary:
      return .secondaryButtonBackground
    case .destructive:
      return .destructiveButtonBackground
    }
  }
  
  // TODO: Hopefully Luke gives us a white Image, so we don't have to switch here at all
  var arrowImage: UIImage {
    switch self {
    case .primary, .secondary:
      return #imageLiteral(resourceName: "arrowGreen")
    case .destructive:
      return #imageLiteral(resourceName: "arrowRed")
    }
  }
  
  var hasArrow: Bool {
    switch self {
    case .primary(let hasArrow),
         .destructive(let hasArrow),
         .secondary(let hasArrow):
      return hasArrow
    }
  }
}

struct MainButtonView: View {
  
  private var title: String
  private var type: MainButtonType
  private var callback: () -> Void
  
  init(title: String, type: MainButtonType, callback: @escaping () -> Void) {
    self.title = title
    self.type = type
    self.callback = callback
  }
  
  var body: some View {
    Button(action: {
      self.callback()
    }) {
      
      HStack {
        
        if type.hasArrow {
        Rectangle()
          .frame(width: 24, height: 24, alignment: .center)
          .foregroundColor(Color.clear)
        }
        
        Spacer()
        
        Text(title)
          .font(.uiButtonLabel)
          .foregroundColor(.buttonText)
        
        Spacer()
        
        if type.hasArrow {
          ZStack {
            Rectangle()
              .frame(width: 24, height: 24, alignment: .center)
              .cornerRadius(9)
              .background(Color.clear)
              .foregroundColor(.white)
            Image(uiImage: type.arrowImage)
              .resizable()
              .foregroundColor(type.color)
              .frame(width: 24, height: 24, alignment: .center)
            }
            .padding([.trailing, .top, .bottom], 10)
          }
      }
      .frame(height: 46)
      .background(type.color)
      .cornerRadius(9)
    }
  }
}

#if DEBUG
struct PrimaryButtonView_Previews: PreviewProvider {
  static var previews: some View {
    MainButtonView(title: "Got It!", type: .primary(withArrow: true)) {
      print("Tapped!")
    }
  }
}
#endif
