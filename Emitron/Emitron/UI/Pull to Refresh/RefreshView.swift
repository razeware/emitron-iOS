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

struct RefreshView: View {
  @Binding var isRefreshing: Bool
  @Binding var proportion: Double
  
  var body: some View {
    HStack {
      Spacer()
      VStack(alignment: .center) {
        if !isRefreshing {
          PullDownArrowView(proportion: proportion)
            .foregroundColor(.textButtonText)
            .frame(height: 30)
        } else {
          ActivityIndicator(style: .large)
        }
        Text(isRefreshing
          ? Constants.pullToRefreshLoadingMessage
          : Constants.pullToRefreshPullMessage)
          .font(.uiCaption)
          .foregroundColor(.textButtonText)
      }
      Spacer()
    }
  }
}

struct RefreshView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      RefreshView(isRefreshing: .constant(false), proportion: .constant(0))
      RefreshView(isRefreshing: .constant(false), proportion: .constant(0.2))
      RefreshView(isRefreshing: .constant(false), proportion: .constant(0.4))
      RefreshView(isRefreshing: .constant(false), proportion: .constant(0.6))
      RefreshView(isRefreshing: .constant(false), proportion: .constant(0.8))
      RefreshView(isRefreshing: .constant(false), proportion: .constant(1))
      RefreshView(isRefreshing: .constant(true), proportion: .constant(0.4))
    }
  }
}
