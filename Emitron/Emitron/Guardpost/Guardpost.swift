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

public enum LoginError: Error {
  case unableToCreateLoginUrl
  case errorResponseFromGuardpost(Error?)
  case unableToDecodeGuardpostResponse
  case invalidSignature
  case unableToCreateValidUser
}

public class Guardpost {
  
  static var current: Guardpost {
    return (UIApplication.shared.delegate as! AppDelegate).guardpost!
  }

  // MARK: - Properties
  private let baseUrl: String
  private let urlScheme: String
  private let ssoSecret: String
  private var _currentUser: UserModel?
  private var authSession: ASWebAuthenticationSession?
  private let persistentStore: PersistenceStore
  public weak var presentationContextDelegate: ASWebAuthenticationPresentationContextProviding?

  public var currentUser: UserModel? {
    if _currentUser == .none {
      _currentUser = persistentStore.userFromKeychain()
    }
    return _currentUser
  }

  // MARK: - Initializers
  init(baseUrl: String,
       urlScheme: String,
       ssoSecret: String,
       persistentStore: PersistenceStore) {
    self.baseUrl = baseUrl
    self.urlScheme = urlScheme
    self.ssoSecret = ssoSecret
    self.persistentStore = persistentStore
  }

  public func login(callback: @escaping (Result<UserModel, LoginError>) -> Void) {
    let guardpostLogin = "\(baseUrl)/v2/sso/login"
    let returnUrl = "\(urlScheme)sessions/create"
    let ssoRequest = SingleSignOnRequest(endpoint: guardpostLogin,
                                         secret: ssoSecret,
                                         callbackUrl: returnUrl)

    guard let loginUrl = ssoRequest.url else {
      let result: Result<UserModel, LoginError> = .failure(.unableToCreateLoginUrl)
      return asyncResponse(callback: callback, result: result)
    }

    authSession = ASWebAuthenticationSession(url: loginUrl,
                                             callbackURLScheme: urlScheme) { url, error in

      var result: Result<UserModel, LoginError>

      guard let url = url else {
        result = .failure(LoginError.errorResponseFromGuardpost(error))
        return self.asyncResponse(callback: callback, result: result)
      }

      guard let response = SingleSignOnResponse(request: ssoRequest, responseUrl: url) else {
        result = .failure(LoginError.unableToDecodeGuardpostResponse)
        return self.asyncResponse(callback: callback, result: result)
      }

      if !response.isValid {
        result = .failure(LoginError.invalidSignature)
        return self.asyncResponse(callback: callback, result: result)
      }

      guard let user = response.user else {
        result = .failure(LoginError.unableToCreateValidUser)
        return self.asyncResponse(callback: callback, result: result)
      }

      self.persistentStore.persistUserToKeychain(user: user)
      self._currentUser = user

      result = Result<UserModel, LoginError>.success(user)
      return self.asyncResponse(callback: callback, result: result)
    }

    authSession?.presentationContextProvider = presentationContextDelegate
    authSession?.start()
  }

  public func cancelLogin() {
    authSession?.cancel()
  }

  public func logout() {
    persistentStore.removeUserFromKeychain()
    _currentUser = .none
  }

  private func asyncResponse(callback: @escaping (Result<UserModel, LoginError>) -> Void,
                             result: Result<UserModel, LoginError>) {
    DispatchQueue.global(qos: .userInitiated).async {
      callback(result)
    }
  }
}
