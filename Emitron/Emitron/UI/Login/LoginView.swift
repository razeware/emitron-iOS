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

struct LoginView: View {
  
  @ObservedObject var userMC: UserMC
  @State var showModal: Bool = false
  
  var body: some View {
    return contentView
      .background(Color.backgroundColor)
  }
  
  private var contentView: AnyView {
    guard userMC.user == nil else {
      let guardpost = Guardpost.current
      let filters = DataManager.current!.filters
      let contentsMC = ContentsMC(guardpost: guardpost, filters: filters)
      let emitronState = AppState()
      
      return AnyView(TabNavView().environmentObject(contentsMC).environmentObject(emitronState))
    }
    
    return AnyView(loginView)
  }
  
  private var loginView: some View {
    VStack {
      
      Image("logo")
        .padding([.top], 15)
      
      Spacer()
      
      Image("welcomeArtwork1")
        .padding([.bottom], 50)
      
      Text("Watch anytime,\nanywhere")
        .font(.uiTitle1)
        .foregroundColor(.titleText)
        .padding([.bottom], 15)
        .multilineTextAlignment(.center)
      
      Text("raywenderlich Subscribers can watch over\n2,000+ video tutorials on iPhone and iPad.")
        .font(.uiLabel)
        .foregroundColor(.contentText)
        .multilineTextAlignment(.center)
      
      Spacer()
      
      MainButtonView(title: "Sign In", type: .primary(withArrow: true)) {
        self.userMC.login()
      }
      .padding([.bottom, .leading, .trailing], 18)
    }
  }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {

  static var previews: some View {
    let guardpost = Guardpost.current
    let userMC = UserMC(guardpost: guardpost)
    
    return LoginView(userMC: userMC)
  }
}
#endif
