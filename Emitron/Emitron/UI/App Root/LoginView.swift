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

struct LoginView: View {
  @EnvironmentObject var sessionController: SessionController
  
  var body: some View {
    VStack {
      
      Image("logo")
        .padding([.top], 88)
      
      Spacer()
      
      PagerView(pageCount: 2, showIndicator: true) {
        VStack {
          Image("welcomeArtwork1")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 265)
            .padding([.bottom], 40)
          
          Text("Watch anytime,\nanywhere")
            .font(.uiTitle1)
            .foregroundColor(.titleText)
            .multilineTextAlignment(.center)
            .padding([.bottom], 15)
          
          Text("Watch over 3,000+ video tutorials\non iPhone and iPad.")
            .font(.uiLabel)
            .foregroundColor(.contentText)
            .multilineTextAlignment(.center)
        }
        .background(Color.backgroundColor)
        
        VStack {
          Image("welcomeArtwork2")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 265)
            .padding([.bottom], 40)
          
          Text("Take your videos on\nthe go")
            .font(.uiTitle1)
            .foregroundColor(.titleText)
            .multilineTextAlignment(.center)
            .padding([.bottom], 15)
          
          Text("Download and watch videos — even\nwhen you’re offline.")
            .font(.uiLabel)
            .foregroundColor(.contentText)
            .multilineTextAlignment(.center)
        }
          .background(Color.backgroundColor)
      }
      
      Spacer()
      
      MainButtonView(title: "Sign In", type: .primary(withArrow: true)) {
        self.sessionController.login()
      }
      .padding([.leading, .trailing], 18)
      .padding([.bottom], 38)
    }
    .background(Color.backgroundColor)
    .edgesIgnoringSafeArea([.all])
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView()
  }
}
