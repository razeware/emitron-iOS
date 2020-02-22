/// Copyright (c) 2020 Razeware LLC
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

struct CardContainerView: View {
  let model: ContentListDisplayable
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel
  
  var body: some View {
    dynamicContentViewModel.initialiseIfRequired()
    
    return CardView(
      model: model,
      dynamicContent: dynamicContentViewModel as DynamicContentDisplayable
    )
      // This if is a no-op that ensures that this view will realise that
      // it should redraw the card if the dynamic content view model changes
      // We do it so that we can easily work on the appearance of the card
      // with mock data, adopting the DynamicContentDisplayable protocol.
      // This might not be the best way to do it. But I don't know of a
      // better way at the moment. Sorry.
      .if(dynamicContentViewModel.state != .hasData) {
        $0.background(Color.clear)
      }
  }
}

//struct CardContainerView_Previews: PreviewProvider {
//  static var previews: some View {
//    CardContainerView()
//  }
//}
