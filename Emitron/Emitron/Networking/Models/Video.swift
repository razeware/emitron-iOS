//
//  Video.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Video {
  
  var id: String?
  var name: String?
  var description: String?
  var free: Bool?
  
  // There's something funky going on with Date's in Xcode 11
  var releasedAt: Date?
  var createdAt: Date?
  var updatedAt: Date?
  
  init(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    
    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String
    self.description = jsonResource["description"] as? String
    self.free = jsonResource["free"] as? Bool
    
    if let releasedAt = jsonResource["released_at"] as? String {
      self.releasedAt = DateFormatter.apiDateFormatter.date(from: releasedAt) ?? Date()
    } else {
      self.releasedAt = Date()
    }
    
    if let createdAtStr = jsonResource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }
    
    if let updatedAtStr = jsonResource["updated_at"] as? String {
      self.updatedAt = DateFormatter.apiDateFormatter.date(from: updatedAtStr) ?? Date()
    } else {
      self.updatedAt = Date()
    }
  }
}
