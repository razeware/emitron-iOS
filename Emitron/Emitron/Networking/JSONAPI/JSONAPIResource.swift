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

import struct Foundation.URL
import SwiftyJSON

public class JSONAPIResource {

  // MARK: - Properties
  weak var parent: JSONAPIDocument?
  var id: Int = 0
  var type: String = ""
  var relationships: [JSONAPIRelationship] = []
  var attributes: [String: Any] = [:]
  var links: [String: URL] = [:]
  var meta: [String: Any] = [:]
  var entityType: EntityType? {
    EntityType(from: type)
  }
  
  var entityId: EntityIdentity? {
    guard let entityType = entityType else { return nil }
    
    return EntityIdentity(id: id, type: entityType)
  }

  public subscript(key: String) -> Any? {
    attributes[key]
  }

  // MARK: - Initializers
  convenience init(_ json: JSON,
                   parent: JSONAPIDocument?) {

    self.init()

    if let doc = parent {
      self.parent = doc
    }

    id = json["id"].intValue
    type = json["type"].stringValue

    for relationship in json["relationships"].dictionaryValue {
      relationships.append(
        JSONAPIRelationship(relationship.value,
                            type: relationship.key,
                            parent: nil)
      )
    }

    attributes = json["attributes"].dictionaryObject ?? [:]

    if let linksDict = json["links"].dictionaryObject {
      for link in linksDict {
        if let strValue = link.value as? String,
          let url = URL(string: strValue) {
            links[link.key] = url
        }
      }
    }

    meta = json["meta"].dictionaryValue
  }
}

extension JSONAPIResource {
  subscript<K: CustomStringConvertible, T>(key: K) -> T? {
    self[key.description] as? T
  }
}
