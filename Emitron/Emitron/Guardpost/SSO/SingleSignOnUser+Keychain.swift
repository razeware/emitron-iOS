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

fileprivate let SSO_USER_KEY = "com.razeware.guardpostkit.sso_user"

internal extension User {
  @discardableResult
  func persistToKeychain() -> Bool {
    let encoder = JSONEncoder()
    guard let encoded = try? encoder.encode(self) else {
      return false
    }
    
    let keychain = KeychainSwift()
    return keychain.set(encoded, forKey: SSO_USER_KEY, withAccess: .accessibleAfterFirstUnlock)
  }
  
  static func restoreFromKeychain() -> User? {
    let keychain = KeychainSwift()
    guard let encoded = keychain.getData(SSO_USER_KEY) else {
      return .none
    }
    
    let decoder = JSONDecoder()
    return try? decoder.decode(self, from: encoded)
  }
  
  @discardableResult
  static func removeUserFromKeychain() -> Bool {
    let keychain = KeychainSwift()
    return keychain.delete(SSO_USER_KEY)
  }
}

