// Copyright (c) 2019 Razeware LLC
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

enum AppliedFilterType {
  case `default`
  case destructive
  
  var backgroundColor: Color {
    switch self {
    case .default:
      return .filterTagBackground
    case .destructive:
      return .filterTagDestructiveBackground
    }
  }
  
  var borderColor: Color {
    switch self {
    case .default:
      return .filterTagBorder
    case .destructive:
      return .filterTagDestructiveBorder
    }
  }
  
  var textColor: Color {
    switch self {
    case .default:
      return .filterTagText
    case .destructive:
      return .filterTagDestructiveText
    }
  }
  
  var iconColor: Color {
    switch self {
    case .default:
      return .filterTagIcon
    case .destructive:
      return .filterTagDestructiveIcon
    }
  }
}

private enum Layout {
  enum Padding {
    static let overall: CGFloat = 10
    static let textTrailing: CGFloat = 2
  }
  
  static let cornerRadius: CGFloat = 9
  static let imageSize: CGFloat = 10
}

struct AppliedFilterTagButton: View {
  let name: String
  let type: AppliedFilterType
  let removeFilterAction: () -> Void
  
  var body: some View {
    Button(action: removeFilterAction) {
      HStack(spacing: 7) {
        Text(name)
          .foregroundColor(type.textColor)
          .font(.uiButtonLabelSmall)
        Image(systemName: "multiply")
          .resizable()
          .frame(width: Layout.imageSize, height: Layout.imageSize)
          .foregroundColor(type.iconColor)
      }
        .padding(.all, Layout.Padding.overall)
    .background(
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .fill(type.backgroundColor)
        .overlay(
          RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .stroke(type.borderColor, lineWidth: 2)
        )
      )
    }
    .padding(1)
  }
}

#if DEBUG
struct AppliedFilterView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      tags.colorScheme(.dark)
      tags.colorScheme(.light)
    }
  }
  
  static var tags: some View {
    HStack {
      AppliedFilterTagButton(name: "Clear All", type: .destructive) { }
      AppliedFilterTagButton(name: "Test Filter", type: .default) { }
      AppliedFilterTagButton(name: "Another", type: .default) { }
    }
    .padding()
    .background(Color.backgroundColor)
  }
}
#endif
