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

import CoreData
import Foundation

enum DomainLevel: String {
  // Production + Beta are the only user-facing ones
  case none
  case production
  case beta
  case blog
  case archive
  case retired
}

class DomainModel {

  // MARK: - Properties
  private(set) var id: Int = 0
  private(set) var name: String = ""
  private(set) var slug: String = ""
  private(set) var description: String = ""
  private(set) var level: DomainLevel = .none

  // MARK: - Initializers
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String ?? ""
    self.slug = jsonResource["slug"] as? String ?? ""
    self.description = jsonResource["description"] as? String ?? ""

    if let domainLevel = DomainLevel(rawValue: jsonResource["level"] as? String ?? DomainLevel.none.rawValue) {
      self.level = domainLevel
    }
  }

  /// Convenience initializer to transform core data **DomainEntity** into a **Domain** model
  ///
  /// - parameters:
  ///   - domain: core data entity to transform into domain model
  init(_ domain: Domain) {
    self.id = domain.id.intValue
    self.name = domain.name
    self.slug = domain.slug
    self.level = DomainLevel(rawValue: domain.level) ?? .none
    if let description = domain.desc {
      self.description = description
    }
  }
}
