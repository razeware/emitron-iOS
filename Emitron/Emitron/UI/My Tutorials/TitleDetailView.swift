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
  static let padding: CGFloat = 20
  static let smallPadding: CGFloat = 2
}

struct TitleDetailView: View {
  
  var callback: (() -> Void)?
  var title: String
  var detail: String?
  var isToggle: Bool
  var isOn: Bool
  var rightImageName: String?
  
  var body: some View {
    Button(action: {
      if !self.isToggle {
        self.callback?()
      }
    }, label: {
      
      VStack {
        HStack {
          Text(self.title)
            .foregroundColor(.appBlack)
            .font(.uiBodyAppleDefault)
            .padding([.leading,.trailing], Layout.padding)
          
          Spacer()
          
          self.textOrToggleView()
          self.addRightImage()
        }
        
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color.paleBlue)
          .padding([.leading, .trailing], Layout.padding)
      }
    })
    .background(Color.paleGrey)
  }
  
  private func textOrToggleView() -> AnyView? {
    if let detail = detail, !isToggle {
      let textView = Text(detail)
        .foregroundColor(.appBlack)
        .font(.uiBodyAppleDefault)
        .padding([.leading], Layout.padding)
        .padding([.trailing], Layout.smallPadding)
      
      return AnyView(textView)

    } else if self.isToggle {
      let toggle = CustomToggleView(isOn: self.isOn) {
        self.callback?()
      }
      .padding([.trailing], Layout.padding)
      return AnyView(toggle)
    }
    
    return nil
  }
  
  private func addRightImage() -> AnyView? {
    if let imageName = self.rightImageName, !self.isToggle {
        let image = Image(imageName)
        .resizable()
        .frame(maxWidth: 13, maxHeight: 13)
        .padding([.trailing], Layout.padding)
        .foregroundColor(.coolGrey)
      
      return AnyView(image)
      
    }
    
    return nil
  }
}

#if DEBUG
struct TitleDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    TitleDetailView(title: "Title", detail: "Detail", isToggle: false, isOn: false, rightImageName: nil)
  }
}
#endif
