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
  
  // Something funny going on with dates in Xcode 11! when you mark them as optional they'll always say they're nil
  // Does not happen in Xcode 10
  let createdAt: Date
  
  init?(resource: JSONAPIResource, metadata: [String: Any]?) {
    self.bookmarkId = resource.id
    
    if let createdAtStr = resource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }
  }
}


