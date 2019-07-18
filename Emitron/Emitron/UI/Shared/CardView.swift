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
import Kingfisher
import UIKit

struct CardView: View {
  
//  @State private var uiImage: UIImage = #imageLiteral(resourceName: "loading5")
  let content: ContentDetail?
//  public let imageURL: URL?
//  public let animation: Animation = .basic()
  
  //TODO - Multiline Text: There are some issues with giving views frames that result in .lineLimit(nil) not respecting the command, and
  // results in truncating the text
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 5) {
          
          Text(content?.name ?? "")
            .lineLimit(nil)
            .font(.uiTitle4)
          
          Text(content?.domains?.first?.name ?? "")
            .font(.uiCaption)
            .lineLimit(nil)
            .foregroundColor(.battleshipGrey)
        }
        
        Spacer()
        
//        Image(uiImage: uiImage)
//          .resizable()
//          .onAppear(perform: loadImage)
//          .transition(.opacity)
//          .id(uiImage)
      }
      
      Text(content?.description ?? "")
        .font(.uiCaption)
        .lineLimit(nil)
        .foregroundColor(.battleshipGrey)
      
      Spacer()
      
      HStack {
        Text(content?.dateAndTimeString ?? "")
          .font(.uiCaption)
          .lineLimit(1)
          .foregroundColor(.battleshipGrey)
        
        Spacer()
        
        Image("download")
          .resizable()
          .frame(width: 19, height: 19)
          .foregroundColor(.darkSeaGreen)
          .tapAction {
            self.download()
          }
      }
    }
      .padding([.leading, .trailing, .top], 15)
      .padding([.bottom], 22)
      .frame(minWidth: 339, minHeight: 184)
      .background(Color.white)
      .cornerRadius(6)
      .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)
  }
  
  private func download() { }
}

#if DEBUG
struct CardView_Previews: PreviewProvider {
  static var previews: some View {
    CardView(content: ContentDetail())
  }
}
#endif
