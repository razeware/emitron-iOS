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

let sso = "3c62ef6384b3becef0261f4b612278d45e46618127194cfc380497997a7150e8083afe8e950f54801adfc25d9af7f949b01656ea0543943a6145ffc1ae013115"

enum EmitronState {
  case noData
  case loading
  case hasData
}

class Emitron: NSObject, BindableObject {
  
  let guardpost = Guardpost(baseUrl: "https://accounts.raywenderlich.com",
                            urlScheme: "com.razeware.emitron://",
                            ssoSecret: sso)
  
  var libraryContent: [ContentDetail] = []
  
  /// `Publisher` required by `BindableObject` protocol. This publisher gets sent a new `Void` value anytime `appState` changes.
  private(set) var didChange = PassthroughSubject<Void, Never>()
  
  /// This is the app's entire state. The SwiftUI view hierarchy is a function of this state.
  private(set) var emitronState = EmitronState.noData {
    didSet {
      didChange.send(())
    }
  }
  
  func guardpostCheck() {
    
    if let user = guardpost.currentUser {
      performRequest(user)
    } else {
      guardpostLogin()
    }
  }
  
  func guardpostLogin() {
    guardpost.presentationContextDelegate = self
    
    guardpost.login { result in
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let user):
        self.performRequest(user)
      }
    }
  }
  
  func performRequest(_ user: User) {
    
    emitronState = .loading
    
    let client = RWAPI(authToken: "\(user.token)")
    //let service =  ProgressionsService(client: client)
    let contentsService = ContentsService(client: client)
    
    let filterParams = Param.filter(by: [.contentTypes(types: [.collection])])
    let sortParam = Param.sort(by: .releasedAt, descending: true)
    let completionParam = ParameterKey.completionStatus(status: .completed).param
    let pageSizeParam = ParameterKey.pageSize(size: 21).param
    let params = filterParams + [sortParam] + [pageSizeParam]
    
    //    service.progressions(parameters: params) { result in
    //      switch result {
    //      case .failure(let error):
    //        print(error.localizedDescription)
    //      case .success(let progressions):
    //        print(progressions.count)
    //      }
    //    }
    contentsService.allContents(parameters: params) { result in
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let contents):
        print(contents.count)
        self.libraryContent = contents
        self.emitronState = .hasData
      }
    }
  }
}

extension Emitron: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.windows.first!
  }
}
