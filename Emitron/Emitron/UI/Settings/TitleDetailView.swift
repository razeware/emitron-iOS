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

private enum Layout {
  static let padding: CGFloat = 11
}

struct TitleDetailView: View {
  
  var callback: (() -> Void)?
  var title: String
  var detail: String?
  var isToggle: Bool
  var isOn: Bool
  var rightImage: Image?
  
  var body: some View {
    Button(action: {
      if !self.isToggle {
        self.callback?()
      }
    }, label: {
      
      VStack(spacing: 0) {
        HStack {
          Text(self.title)
            .foregroundColor(.titleText)
            .font(.uiBodyAppleDefault)
            .padding([.vertical], Layout.padding)
          
          Spacer()
          
          self.textOrToggleView()
          self.addRightImage()
        }
        
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color.separator)
      }
    })
  }
  
  private func textOrToggleView() -> AnyView? {
    if let detail = detail, !isToggle {
      return AnyView(
        Text(detail)
          .foregroundColor(.iconButton)
          .font(.uiBodyAppleDefault)
      )
    } else if self.isToggle {
      return AnyView(
        CustomToggleView(isOn: self.isOn) {
          self.callback?()
        }
      )
    }
    
    return nil
  }
  
  private func addRightImage() -> AnyView? {
    if let rightImage = rightImage, !self.isToggle {
      return AnyView(
        rightImage
          .foregroundColor(.iconButton)
      )
    }
    
    return nil
  }
}

#if DEBUG
struct TitleDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      rows.colorScheme(.dark)
      rows.colorScheme(.light)
    }
  }
  
  static var rows: some View {
    VStack(spacing: 0) {
      TitleDetailView(
        title: "Title",
        detail: "Detail",
        isToggle: false,
        isOn: false,
        rightImage: Image(systemName: "chevron.right")
      )
      
      TitleDetailView(
        title: "Boolean",
        detail: "Detail",
        isToggle: true,
        isOn: true
      )
    }.background(Color.backgroundColor)
  }
}
#endif
