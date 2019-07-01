//
//  Bookmark.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Bookmark {
  let bookmarkId: String
  let createdAt: Date?
  
  init?(resource: JSONAPIResource, metadata: [String: Any]?) {
    self.bookmarkId = resource.id
    
    if let createdAtStr = resource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }
  }
}


