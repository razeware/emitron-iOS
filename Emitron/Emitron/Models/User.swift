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

import struct Foundation.URL

public struct User: Equatable, Codable {
  public let externalID: String
  public let email: String
  public let username: String
  public let avatarURL: URL
  public let name: String
  public let token: String
  let permissions: [Permission]?
}

// MARK: - internal
extension User {
  init?(dictionary: [String: String]) {
    guard
      let externalID = dictionary["external_id"],
      let email = dictionary["email"],
      let username = dictionary["username"],
      let avatarURLString = dictionary["avatar_url"],
      let avatarURL = URL(string: avatarURLString),
      let name = dictionary["name"]?.replacingOccurrences(of: "+", with: " "),
      let token = dictionary["token"]
    else { return nil }

    self.externalID = externalID
    self.email = email
    self.username = username
    self.avatarURL = avatarURL
    self.name = name
    self.token = token
    permissions = .none
  }

  func with(permissions: [Permission]) -> User {
    .init(user: self, permissions: permissions)
  }
}

// MARK: public
public extension User {
  var canStreamPro: Bool { can(.streamPro) }
  var canStream: Bool { can(.streamBeginner) }
  var canDownload: Bool { can(.download) }

  var hasPermissionToUseApp: Bool {
    canStreamPro || canStream || canDownload
  }
}

// MARK: - private
private extension User {
  init(user: User, permissions: [Permission]) {
    externalID = user.externalID
    email = user.email
    username = user.username
    avatarURL = user.avatarURL
    name = user.name
    token = user.token
    self.permissions = permissions
  }

  func can(_ tag: Permission.Tag) -> Bool {
    permissions?.lazy.map(\.tag).contains(tag) == true
  }
}
