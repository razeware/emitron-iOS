// Copyright (c) 2020 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import SwiftUI

struct IconView: View {
  let icon: Icon
  let selected: Bool
  
  var body: some View {
    Image(uiImage: icon.uiImage)
      .renderingMode(.original)
      .cornerRadius(10)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.appIconBorder, lineWidth: 2)
      )
      .padding([.trailing], 2)
      .if(selected) {
        $0.overlay(
          Image(systemName: "checkmark.circle.fill")
            .font(Font.system(size: 20, weight: .bold))
            .foregroundColor(.accent),
          alignment: .bottomTrailing
        )
      }
  }
}

struct IconView_Previews: PreviewProvider {
  static let darkIcon = Icon(name: nil, imageName: "app-icon--default", ordinal: 0)
  static let lightIcon = Icon(name: "black-white", imageName: "app-icon--black-white", ordinal: 0)
  
  static var previews: some View {
    SwiftUI.Group {
      icons.colorScheme(.light)
      icons.colorScheme(.dark)
    }
  }
  
  static var icons: some View {
    HStack {
      IconView(icon: darkIcon, selected: false)
      IconView(icon: darkIcon, selected: true)
      IconView(icon: lightIcon, selected: false)
      IconView(icon: lightIcon, selected: true)
    }
      .padding()
      .background(Color.backgroundColor)
  }
}
