//
//  Progression.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Progression {
  var id: String?
  var target: Int?
  var progress: Int?
  var finished: Bool?
  var percentComplete: Double?
  // There's something funky going on with Date's in Xcode 11
  var createdAt: Date?
  var updatedAt: Date?
  
  init(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    
    self.id = jsonResource.id
    self.target = jsonResource["target"] as? Int
    self.progress = jsonResource["progress"] as? Int
    self.finished = jsonResource["finished"] as? Bool
    self.percentComplete = jsonResource["percent_complete"] as? Double
    self.finished = jsonResource["finished"] as? Bool
    
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
