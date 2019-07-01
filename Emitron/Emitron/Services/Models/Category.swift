//
//  Category.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Category {
  
  var id: String?
  var url: URL?
  var ordinal: Double?
  
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    
    self.id = jsonResource.id
    self.url = URL(string: (jsonResource["name"] as? String) ?? "")
    self.ordinal = jsonResource["ordinal"] as? Double
  }
}

