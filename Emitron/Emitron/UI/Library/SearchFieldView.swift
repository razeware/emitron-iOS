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

struct SearchFieldView: View {
  private struct SizeKey: PreferenceKey {
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
      value = value ?? nextValue()
    }
  }
  
  @State var searchString: String = ""
  var action: (String) -> Void = { _ in }
  @State private var height: CGFloat?
  
  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.searchFieldIcon)
        .frame(height: 25)
      
      TextField(Constants.search, text: $searchString) {
        self.action(self.searchString)
      }
        .keyboardType(.webSearch)
        .font(.uiBodyCustom)
        .foregroundColor(.searchFieldText)
        .contentShape(Rectangle())
      
      if !searchString.isEmpty {
        Button(action: {
          self.searchString = ""
          self.action(self.searchString)
        }) {
          Image(systemName: "multiply.circle.fill")
            // If we don't enforce a frame, the button doesn't register the tap action
            .frame(width: 25, height: 25, alignment: .center)
            .foregroundColor(.searchFieldIcon)
        }
      }
    }
      .padding([.vertical], 6)
      .padding([.horizontal], 10)
      .background(GeometryReader { proxy in
        Color.clear.preference(key: SizeKey.self, value: proxy.size)
      })
      .frame(height: height)
      .background(background)
      .padding(1)
      .padding([.bottom], 2)
      .onPreferenceChange(SizeKey.self) { size in
        self.height = size?.height
      }
  }
  
  var background: some View {
    RoundedRectangle(cornerRadius: 9)
      .fill(Color.searchFieldBackground)
      .shadow(color: .searchFieldShadow, radius: 1, x: 0, y: 2)
      .overlay(
        RoundedRectangle(cornerRadius: 9)
          .stroke(Color.searchFieldBorder, lineWidth: 2)
      )
  }
}

struct SearchFieldView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      searchFields.colorScheme(.light)
      searchFields.colorScheme(.dark)
    }
  }
  
  static var searchFields: some View {
    VStack(spacing: 20) {
      SearchFieldView(searchString: "")
      SearchFieldView(searchString: "Hello")
      SearchFieldView(searchString: "Testing")
    }
      .padding(20)
      .background(Color.backgroundColor)
  }
}
