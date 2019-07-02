//
//  User.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

public struct User: Codable {
  
  public let externalId: String
  public let email: String
  public let username: String
  public let avatarUrl: URL
  public let name: String
  public let token: String
  
  internal init?(dictionary: [String: String]) {
    guard
      let externalId = dictionary["external_id"],
      let email = dictionary["email"],
      let username = dictionary["username"],
      let avatarUrlString = dictionary["avatar_url"],
      let avatarUrl = URL(string: avatarUrlString),
      let name = dictionary["name"]?.replacingOccurrences(of: "+", with: " "),
      let token = dictionary["token"]
      else
    { return nil }
    
    self.externalId = externalId
    self.email = email
    self.username = username
    self.avatarUrl = avatarUrl
    self.name = name
    self.token = token
  }
}

extension User: Equatable {
  public static func ==(lhs: User, rhs: User) -> Bool {
    return lhs.externalId == rhs.externalId &&
      lhs.email == rhs.email &&
      lhs.username == rhs.username &&
      lhs.avatarUrl == rhs.avatarUrl &&
      lhs.name == rhs.name &&
      lhs.token == rhs.token
  }
}
