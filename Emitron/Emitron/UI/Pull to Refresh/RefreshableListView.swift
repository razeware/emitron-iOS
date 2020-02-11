//  MIT License
//
//  Copyright (c) 2019 Andras Samu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftUI

struct RefreshableListView<Content: View>: View {
  @State var showRefreshView: Bool = false
  @State var pullProportion: Double = 0
  let action: (_ completion: @escaping () -> Void) -> Void
  let content: () -> Content
  
  init(action: @escaping (_ completion: @escaping () -> Void) -> Void, @ViewBuilder content: @escaping () -> Content) {
    self.action = action
    self.content = content
  }
  
  var body: some View {
    List {
      PullToRefreshView(showRefreshView: $showRefreshView,
                        pullProportion: $pullProportion)
      content()
    }
    .onPreferenceChange(PullToRefreshPreferenceKeyTypes.PrefKey.self) { values in
      guard let bounds = values.first?.bounds else { return }
      self.pullProportion = Double((bounds.origin.y - 106) / 80)
      self.refresh(offset: bounds.origin.y)
    }
    .offset(x: 0, y: -40)
  }
  
  func refresh(offset: CGFloat) {
    if offset > 185 && self.showRefreshView == false {
      self.showRefreshView = true
      DispatchQueue.main.async {
        self.action {
          DispatchQueue.main.async {
            self.showRefreshView = false
          }
        }
      }
    }
  }
}

struct RefreshableListView_Previews: PreviewProvider {
  static var previews: some View {
    RefreshableListView(
      action: { completion in
        print("REFRESHHHIIIGNNNG")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          completion()
        }
      }) {
      ForEach(0...10, id: \.self) { number in
        VStack(alignment: .leading) {
          Text("\(number)")
          Divider()
        }
      }
    }
  }
}
