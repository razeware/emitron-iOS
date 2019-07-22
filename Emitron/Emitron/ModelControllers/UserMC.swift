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

import AuthenticationServices
import Foundation
import SwiftUI
import Combine
import Firebase

class UserMC: NSObject, BindableObject {
  
  /// `Publisher` required by `BindableObject` protocol. This publisher gets sent a new `Void` value anytime `appState` changes.
  private(set) var willChange = PassthroughSubject<Void, Never>()
  
  /// This is the app's entire state. The SwiftUI view hierarchy is a function of this state.
  private(set) var state = DataState.initial {
    didSet {
      willChange.send(())
    }
  }
  
  private let client: RWAPI
  private let guardpost: Guardpost
  private(set) var user: User?
  
  // MARK: - Initializers
  init(guardpost: Guardpost) {
    self.guardpost = guardpost
    self.user = guardpost.currentUser
    self.client = RWAPI(authToken: self.user?.token ?? "")
  }
  
  // MARK: - Internal
  func login() {
    state = .loading
    guardpost.presentationContextDelegate = self
    
    if user != nil {
      state = .hasData
    } else {
      guardpost.login { [weak self] result in
        
        guard let self = self else {
          return
        }
        
        switch result {
        case .failure(let error):
          self.state = .failed
          
          Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemName: "Failed to login!",
            AnalyticsParameterContent: error.localizedDescription
          ])
          
        case .success(let user):
          self.user = user
          self.state = .hasData
        }
      }
    }
  }
}

extension UserMC: ASWebAuthenticationPresentationContextProviding {
  
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.windows.first!
  }
}
