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
import KeychainSwift

// The object responsible for managing and accessing cached content

final class PersistenceStore {
  
  static var current: PersistenceStore {
    return (UIApplication.shared.delegate as! AppDelegate).persistentStore
  }
  
  let coreDataStack = CoreDataStack()
  
  init() {
    setupPersistentStore()
  }
  
  private func setupPersistentStore() {
    coreDataStack.setupPersistentContainer()
  }
}

// MARK: Documents Directory
// For storing downloaded video files which expire after 7 days

extension PersistenceStore { }

// MARK: CoreData
// For storing information that should not change that frequently
// content (refresh daily)
// categories (very infrequently)
// domains (very infrequently)

extension PersistenceStore {
  // let storedContent = store.objects(CDContent)
  // let content = storedContent.compactMap { $0.contentobjects() }
    
    func objects<T>(_ type: T.Type) -> [T] {
      return []
    }
}

// MARK: UserDefaults
// For saving individual search/filter preferences
// Progress for contentID
// App Settings

extension PersistenceStore { }

// MARK: Keychain
// User + Auth Token (refresh daily)

private let SSOUserKey = "com.razeware.emitron.sso_user"

extension PersistenceStore {
  
  @discardableResult
  func persistUserToKeychain(user: UserModel, encoder: JSONEncoder = JSONEncoder()) -> Bool {
    guard let encoded = try? encoder.encode(user) else {
      return false
    }
    
    let keychain = KeychainSwift()
    return keychain.set(encoded,
                        forKey: SSOUserKey,
                        withAccess: .accessibleAfterFirstUnlock)
  }
  
  func userFromKeychain(_ decoder: JSONDecoder = JSONDecoder()) -> UserModel? {
    let keychain = KeychainSwift()
    guard let encoded = keychain.getData(SSOUserKey) else {
      return nil
    }
    
    return try? decoder.decode(UserModel.self, from: encoded)
  }
  
  @discardableResult
  func removeUserFromKeychain() -> Bool {
    let keychain = KeychainSwift()
    return keychain.delete(SSOUserKey)
  }
}
