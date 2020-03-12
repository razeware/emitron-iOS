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

struct SingleSignOnRequest {

  // MARK: - Properties
  private let callbackUrl: String
  let secret: String
  let nonce: String
  private let endpoint: String
  var url: URL? {
    var components = URLComponents(string: endpoint)
    components?.queryItems = payload
    return components?.url
  }

  // MARK: - Initializers
  init(endpoint: String,
       secret: String,
       callbackUrl: String) {
    self.endpoint = endpoint
    self.secret = secret
    self.callbackUrl = callbackUrl
    self.nonce = randomHexString(length: 40)
  }
}

// MARK: - Private
private extension SingleSignOnRequest {

  var payload: [URLQueryItem]? {
    guard let unsignedPayload = unsignedPayload else {
      return nil
    }

    let contents = unsignedPayload.toBase64()
    let symmetricKey = SymmetricKey(data: Data(secret.utf8))
    let signature = HMAC<SHA256>.authenticationCode(for: Data(contents.utf8),
                                                    using: symmetricKey)
      .description
      .replacingOccurrences(of: String.hmacToRemove, with: "")

    return [
      URLQueryItem(name: "sso", value: contents),
      URLQueryItem(name: "sig", value: signature)
    ]
  }

  var unsignedPayload: String? {
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: "callback_url", value: callbackUrl),
      URLQueryItem(name: "nonce", value: nonce)
    ]
    return components.query
  }
}
