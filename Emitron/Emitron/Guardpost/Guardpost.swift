// Copyright (c) 2022 Razeware LLC
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
import Combine

public class Guardpost: ObservableObject {
  init(
    baseURL: String,
    urlScheme: String,
    ssoSecret: String,
    persistenceStore: PersistenceStore
  ) {
    self.baseURL = baseURL
    self.urlScheme = urlScheme
    self.ssoSecret = ssoSecret
    self.persistenceStore = persistenceStore
  }

  private let baseURL: String
  private let urlScheme: String
  private let ssoSecret: String
  private let persistenceStore: PersistenceStore
  private var _currentUser: User?
}

// MARK: - public
public extension Guardpost {
  enum LoginError: Error {
    case unableToCreateLoginURL
    case errorResponseFromGuardpost(Error?)
    case unableToDecodeGuardpostResponse
    case invalidSignature
    case unableToCreateValidUser
  }
  
  var currentUser: User? {
    if _currentUser == nil {
      _currentUser = persistenceStore.userFromKeychain()
    }
    return _currentUser
  }

  /// - Throws: `LoginError`
  func login() async throws -> User {
    let guardpostLogin = "\(baseURL)/v2/sso/login"
    let returnURL = "\(urlScheme)://sessions/create"
    let ssoRequest = SingleSignOnRequest(
      endpoint: guardpostLogin,
      secret: ssoSecret,
      callbackURL: returnURL
    )

    guard let loginURL = ssoRequest.url
    else { throw LoginError.unableToCreateLoginURL }

    let user: User = try await withCheckedThrowingContinuation {
      [presentationContextDelegate = PresentationContextDelegate()] continuation in
      let authSession = ASWebAuthenticationSession(
        url: loginURL,
        callbackURLScheme: urlScheme
      ) { url, error in
        guard let url = url else {
          continuation.resume(throwing: LoginError.errorResponseFromGuardpost(error))
          return
        }

        guard let response = SingleSignOnResponse(request: ssoRequest, responseURL: url) else {
          continuation.resume(throwing: LoginError.unableToDecodeGuardpostResponse)
          return
        }

        guard response.isValid else {
          continuation.resume(throwing: LoginError.invalidSignature)
          return
        }

        guard let user = response.user else {
          continuation.resume(throwing: LoginError.unableToCreateValidUser)
          return
        }

        continuation.resume(returning: user)
      }

      authSession.presentationContextProvider = presentationContextDelegate

      // This will prevent sharing cookies with Safari, which means no auto-login
      // However, it also means that you can actually log out, which is good, I guess.
      #if (!DEBUG)
      authSession?.prefersEphemeralWebBrowserSession = true
      #endif

      authSession.start()
    }

    try persistenceStore.persistUserToKeychain(user: user)
    _currentUser = user
    return user
  }

  func logout() {
    try? persistenceStore.removeUserFromKeychain()
    _currentUser = .none
  }
  
  func updateUser(with user: User?) {
    _currentUser = user
    if let user = user {
      try? persistenceStore.persistUserToKeychain(user: user)
    } else {
      try? persistenceStore.removeUserFromKeychain()
    }
  }
}

public extension Guardpost.LoginError {
  var localizedDescription: String {
    let prefix = "GuardpostLoginError::"
    switch self {
    case .unableToCreateLoginURL:
      return "\(prefix)UnableToCreateLoginURL"
    case .errorResponseFromGuardpost(let error):
      return "\(prefix)[Error: \(error?.localizedDescription ?? "UNKNOWN")]"
    case .unableToDecodeGuardpostResponse:
      return "\(prefix)UnableToDecodeGuardpostResponse"
    case .invalidSignature:
      return "\(prefix)InvalidSignature"
    case .unableToCreateValidUser:
      return "\(prefix)UnableToCreateValidUser"
    }
  }
}

// MARK: - private
private final class PresentationContextDelegate: NSObject { }

// MARK: - ASWebAuthenticationPresentationContextProviding
extension PresentationContextDelegate: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
    .init()
  }
}
