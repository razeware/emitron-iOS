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

import Foundation

protocol Log {
  var object: String { get }
  var action: String { get }
  var reason: String { get }

  func log(additionalParams: [String: String]?)
}

// To make "reason" optional
extension Log {
  var reason: String {
    return "N/A"
  }
}

enum Failure: Log {
  
  case login(from: String, reason: String)
  case fetch(from: String, reason: String)
  case loadFromPersistentStore(from: String, reason: String)
  case saveToPersistentStore(from: String, reason: String)
  case deleteFromPersistentStore(from: String, reason: String)
  
  private var failure: String {
    return "Failed_"
  }
  
  var object: String {
    switch self {
    case .login(from: let from, reason: _),
         .fetch(from: let from, reason: _),
         .loadFromPersistentStore(from: let from, reason: _),
         .saveToPersistentStore(from: let from, reason: _),
         .deleteFromPersistentStore(from: let from, reason: _):
      return from
    }
  }
  
  var action: String {
    switch self {
    case .login:
      return failure + "login"
    case .fetch:
      return failure + "fetch"
    case .loadFromPersistentStore:
      return failure + "loadingFromPersistentStore"
    case .saveToPersistentStore:
      return failure + "savingToPersistentStore"
    case .deleteFromPersistentStore:
      return failure + "deleteToPersistentStore"
    }
  }
  
  var reason: String {
    switch self {
    case .login(from: _, reason: let reason),
         .fetch(from: _, reason: let reason),
         .loadFromPersistentStore(from: _, reason: let reason),
         .saveToPersistentStore(from: _, reason: let reason),
         .deleteFromPersistentStore(from: _, reason: let reason):
      return reason
    }
  }
  
  func log(additionalParams: [String: String]?) {
    let params = ["object": self.object,
                  "action": self.action,
                  "reason": self.reason]
    let allParams = params.merged(additionalParams) as [String: Any]
    print(allParams)
  }
}

enum Event: Log {
  
  case login(from: String)
  
  var object: String {
    switch self {
    case .login(from: let from):
      return from
    }
  }
  
  var action: String {
    switch self {
    case .login:
      return "Login"
    }
  }

  func log(additionalParams: [String: String]?) {
    let params = ["object": self.object]
    let allParams = params.merged(additionalParams) as [String: Any]
    print(allParams)
  }
}
