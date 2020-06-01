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

import AuthenticationServices

public enum LoginError: Error {
  case unableToCreateLoginUrl
  case errorResponseFromGuardpost(Error?)
  case unableToDecodeGuardpostResponse
  case invalidSignature
  case unableToCreateValidUser
  
  public var localizedDescription: String {
    let prefix = "GuardpostLoginError::"
    switch self {
    case .unableToCreateLoginUrl:
      return "\(prefix)UnableToCreateLoginUrl"
    case .errorResponseFromGuardpost(let error):
      return "\(prefix)GuardpostLoginError:: [Error: \(error?.localizedDescription ?? "UNKNOWN")]"
    case .unableToDecodeGuardpostResponse:
      return "\(prefix)UnableToDecodeGuardpostResponse"
    case .invalidSignature:
      return "\(prefix)InvalidSignature"
    case .unableToCreateValidUser:
      return "\(prefix)UnableToCreateValidUser"
    }
  }
}

public class Guardpost {
  // MARK: - Properties
  private let baseUrl: String
  private let urlScheme: String
  private let ssoSecret: String
  private var _currentUser: User?
  private var authSession: ASWebAuthenticationSession?
  private let persistenceStore: PersistenceStore
  public weak var presentationContextDelegate: ASWebAuthenticationPresentationContextProviding?

  public var currentUser: User? {
    if _currentUser == .none {
      _currentUser = persistenceStore.userFromKeychain()
    }
    return _currentUser
  }

  // MARK: - Initializers
  init(baseUrl: String,
       urlScheme: String,
       ssoSecret: String,
       persistenceStore: PersistenceStore) {
    self.baseUrl = baseUrl
    self.urlScheme = urlScheme
    self.ssoSecret = ssoSecret
    self.persistenceStore = persistenceStore
  }

  public func login(callback: @escaping (Result<User, LoginError>) -> Void) {
    let guardpostLogin = "\(baseUrl)/v2/sso/login"
    let returnUrl = "\(urlScheme)sessions/create"
    let ssoRequest = SingleSignOnRequest(endpoint: guardpostLogin,
                                         secret: ssoSecret,
                                         callbackUrl: returnUrl)

    guard let loginUrl = ssoRequest.url else {
      let result: Result<User, LoginError> = .failure(.unableToCreateLoginUrl)
      return asyncResponse(callback: callback, result: result)
    }

    authSession = ASWebAuthenticationSession(url: loginUrl,
                                             callbackURLScheme: urlScheme) { url, error in

      var result: Result<User, LoginError>

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

      self.persistenceStore.persistUserToKeychain(user: user)
      self._currentUser = user

      result = Result<User, LoginError>.success(user)
      return self.asyncResponse(callback: callback, result: result)
    }

    authSession?.presentationContextProvider = presentationContextDelegate
    // This will prevent sharing cookies with Safari, which means no auto-login
    // However, it also means that you can actually log out, which is good, I guess.
    authSession?.prefersEphemeralWebBrowserSession = true
    authSession?.start()
  }

  public func cancelLogin() {
    authSession?.cancel()
  }

  public func logout() {
    persistenceStore.removeUserFromKeychain()
    _currentUser = .none
  }
  
  public func updateUser(with user: User?) {
    _currentUser = user
    if let user = user {
      persistenceStore.persistUserToKeychain(user: user)
    } else {
      persistenceStore.removeUserFromKeychain()
    }
  }

  private func asyncResponse(callback: @escaping (Result<User, LoginError>) -> Void,
                             result: Result<User, LoginError>) {
    DispatchQueue.global(qos: .userInitiated).async {
      callback(result)
    }
  }
}
