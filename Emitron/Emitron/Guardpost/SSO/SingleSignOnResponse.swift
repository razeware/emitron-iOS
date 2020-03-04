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

import CryptoKit
import Foundation

struct SingleSignOnResponse {

  // MARK: - Properties
  private let request: SingleSignOnRequest
  private let signature: String
  private let payload: String
  private let decodedPayload: [URLQueryItem]?

  // MARK: - Initializers
  init?(request: SingleSignOnRequest, responseUrl: URL) {
    let responseComponents = URLComponents(url: responseUrl,
                                           resolvingAgainstBaseURL: false)
    var components = URLComponents()
    guard
      let sso = responseComponents?.queryItems?.first(where: { $0.name == "sso" })?.value,
      let sig = responseComponents?.queryItems?.first(where: { $0.name == "sig" })?.value,
      let urlString = sso.fromBase64()
      else {
        return nil
    }

    components.query = urlString

    self.request = request
    self.signature = sig
    self.payload = sso
    self.decodedPayload = components.queryItems
  }

  var isValid: Bool {
    isSignatureValid && isNonceValid
  }

  var user: User? {
    if !isValid {
      return nil
    }
    guard let decodedPayload = decodedPayload else {
      return nil
    }

    let dictionary = queryItemsToDictionary(decodedPayload)
    return User(dictionary: dictionary)
  }
}

// MARK: - Private
private extension SingleSignOnResponse {

  var isSignatureValid: Bool {
    let symmetricKey = SymmetricKey(data: Data(request.secret.utf8))
    let hmac = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8),
                                               using: symmetricKey)
      .description
      .replacingOccurrences(of: String.hmacToRemove, with: "")

    return hmac == signature
  }

  var isNonceValid: Bool {
    decodedPayloadEntry(name: "nonce") == request.nonce
  }

  func decodedPayloadEntry(name: String) -> String? {
    decodedPayload?.first { $0.name == name }?.value
  }

  func queryItemsToDictionary(_ queryItems: [URLQueryItem]) -> [String: String] {
    queryItems.reduce(into: [:]) { result, item in
      result[item.name] = item.value?.removingPercentEncoding
    }
  }
}
