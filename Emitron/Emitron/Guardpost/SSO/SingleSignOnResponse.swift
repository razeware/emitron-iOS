/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import CryptoKit

internal struct SingleSignOnResponse {
  private let request: SingleSignOnRequest
  private let signature: String
  private let payload: String
  private let decodedPayload: [URLQueryItem]?
  
  internal init?(request: SingleSignOnRequest, responseUrl: URL) {
    let responseCmpts = URLComponents(url: responseUrl, resolvingAgainstBaseURL: false)
    var cmpts = URLComponents()
    guard
      let sso = responseCmpts?.queryItems?.first(where: { $0.name == "sso" })?.value,
      let sig = responseCmpts?.queryItems?.first(where: { $0.name == "sig" })?.value,
      let urlString = sso.fromBase64()
      else {
        return nil
    }
    
    cmpts.query = urlString
    
    self.request = request
    self.signature = sig
    self.payload = sso
    self.decodedPayload = cmpts.queryItems
  }
  
  internal var isValid: Bool {
    return isSignatureValid && isNonceValid
  }
  
  internal var user: User? {
    if !isValid {
      return .none
    }
    guard let decodedPayload = decodedPayload else { return .none }
    let dictionary = queryItemsToDictionary(decodedPayload)
    return User(dictionary: dictionary)
  }
  
  private var isSignatureValid: Bool {
    let symmetricKey = SymmetricKey(data: Data(request.secret.utf8))
    let hmac = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: symmetricKey).description.replacingOccurrences(of: String.hmacToRemove, with: "")
    
    return hmac == signature
  }
  
  private var isNonceValid: Bool {
    return decodedPayloadEntry(name: "nonce") == request.nonce
  }
  
  private func decodedPayloadEntry(name: String) -> String? {
    return decodedPayload?.first(where: { $0.name == name })?.value
  }
  
  private func queryItemsToDictionary(_ queryItems: [URLQueryItem]) -> [String : String] {
    var dictionary = [String : String]()
    for item in queryItems {
      dictionary[item.name] = item.value?.removingPercentEncoding
    }
    return dictionary
  }
}




