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

struct SettingsDisclosureRow: View {
  let title: String
  let value: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(title)
          .font(.uiBodyAppleDefault)
          .foregroundColor(.titleText)
          .padding([.vertical], SettingsLayout.rowSpacing)
        
        Spacer()
        
        Text(value)
          .font(.uiBodyAppleDefault)
          .foregroundColor(.contentText)
        
        Image(systemName: "chevron.right")
          .foregroundColor(.iconButton)
      }

      Rectangle()
        .fill(Color.separator)
        .frame(height: 1)
    }
  }
}

struct SettingsDisclosureRow_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      rows.colorScheme(.dark)
      rows.colorScheme(.light)
    }
  }
  
  static var rows: some View {
    SettingsDisclosureRow(title: "Disclosure", value: "HELLO")
      .padding()
      .background(Color.backgroundColor)
  }
}
