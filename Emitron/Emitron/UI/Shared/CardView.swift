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

struct CardView: View {
  
  let content: ContentDetail?
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        VStack {
          Text(content?.name ?? "")
            .frame(width: 214, height: 48, alignment: .topLeading)
            .font(.uiTitle4)
            .lineLimit(2)
          Text(content?.domains?.first?.name ?? "")
            .frame(width: 214, height: 16, alignment: .leading)
            .font(.uiCaption)
            .lineLimit(1)
            .foregroundColor(.battleshipGrey)
        }
        Image("SwiftSquare")
          .resizable()
          .frame(width: 60, height: 60, alignment: .topTrailing)
          .cornerRadius(6)
      }
      Text(content?.description ?? "")
        .frame(width: 214, height: 75, alignment: .topLeading)
        .font(.uiCaption)
        .lineLimit(4)
        .foregroundColor(.battleshipGrey)
      HStack {
        Text(content?.dateAndTimeString ?? "")
          .frame(width: 214, height: 16, alignment: .leading)
          .font(.uiCaption)
          .lineLimit(1)
          .foregroundColor(.battleshipGrey)
        Image("materialIconDownload")
      }
    }
      .frame(width: 340, height: 185, alignment: .center)
      .padding()
      .background(Color.paleBlue)
      .cornerRadius(6)
      .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)
  }
}

#if DEBUG
struct CardView_Previews: PreviewProvider {
  static var previews: some View {
    CardView(content: ContentDetail())
  }
}
#endif
