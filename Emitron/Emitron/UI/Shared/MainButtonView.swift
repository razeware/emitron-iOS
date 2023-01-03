// Copyright (c) 2022 Razeware LLC
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
  
  var hasArrow: Bool {
    switch self {
    case
        .primary(let hasArrow),
        .destructive(let hasArrow),
        .secondary(let hasArrow):
      return hasArrow
    }
  }
}

struct MainButtonView: View {
  private struct SizeKey: PreferenceKey {
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
      value = value ?? nextValue()
    }
  }
  
  @State private var height: CGFloat?
  var title: String
  var type: MainButtonType
  var callback: () -> Void
  
  var body: some View {
    Button {
      callback()
    } label: {
      HStack {
        ZStack(alignment: .center) {
          HStack {
            Spacer()
            
            Text(title)
              .font(.uiButtonLabelLarge)
              .foregroundColor(.buttonText)
              .padding(15)
              .background(GeometryReader { proxy in
                Color.clear.preference(key: SizeKey.self, value: proxy.size)
              })
            
            Spacer()
          }
          
          if type.hasArrow {
            HStack {
              Spacer()
              
              Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .frame(width: height, height: height)
                .foregroundColor(type.color)
                .background(
                  Color.white
                    .cornerRadius(9)
                    .padding(12)
                )
            }
          }
        }
          .frame(height: height)
          .background(
            RoundedRectangle(cornerRadius: 9)
              .stroke(Color.white, lineWidth: 1)
              // Kodeco Reskin skips .fill(type.color)
          )
          .onPreferenceChange(SizeKey.self) { size in
            height = size?.height
          }
      }
    }
  }
}

struct PrimaryButtonView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      MainButtonView(title: "Got It!", type: .primary(withArrow: false), callback: {})
      MainButtonView(title: "Got It!", type: .primary(withArrow: true), callback: {})
      MainButtonView(title: "Got It!", type: .secondary(withArrow: false), callback: {})
      MainButtonView(title: "Got It!", type: .secondary(withArrow: true), callback: {})
      MainButtonView(title: "Got It!", type: .destructive(withArrow: false), callback: {})
      MainButtonView(title: "Got It!", type: .destructive(withArrow: true), callback: {})
    }
      .padding(20)
      .background(Color.background)
      .inAllColorSchemes
  }
}
