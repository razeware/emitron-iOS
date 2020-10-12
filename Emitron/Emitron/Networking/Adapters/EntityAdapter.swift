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

protocol EntityAdapter {
  associatedtype Response
  
  static func process(resource: JSONAPIResource, relationships: [EntityRelationship]) throws -> Response
}

enum EntityType {
  case attachment
  case bookmark
  case category
  case content
  case domain
  case group
  case permission
  case progression
  case video
  
  init?(from string: String) {
    switch string {
    case "attachments":
      self = .attachment
    case "bookmarks":
      self = .bookmark
    case "categories":
      self = .category
    case "contents":
      self = .content
    case "domains":
      self = .domain
    case "groups":
      self = .group
    case "permissions":
      self = .permission
    case "progressions":
      self = .progression
    case "videos":
      self = .video
    default:
      return nil
    }
  }
}

struct EntityIdentity: Identifiable {
  let id: Int
  let type: EntityType
}

struct EntityRelationship {
  let name: String
  let from: EntityIdentity
  let to: EntityIdentity // swiftlint:disable:this identifier_name
}

enum EntityAdapterError: Error {
  case invalidResourceTypeForAdapter
  case invalidOrMissingAttributes
  case invalidOrMissingRelationships
  
  var localizedDescription: String {
    let prefix = "EntityAdapterError::"
    switch self {
    case .invalidResourceTypeForAdapter:
      return "\(prefix)InvalidResourceTypeForAdapter"
    case .invalidOrMissingAttributes:
      return "\(prefix)InvalidOrMissingAttributes"
    case .invalidOrMissingRelationships:
      return "\(prefix)InvalidOrMissingRelationships"
    }
  }
}
