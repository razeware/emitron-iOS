//
//  Gropu.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Group {
  
  var id: String?
  var name: String?
  var description: String?
  var ordinal: Double?
  
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]) {
    
    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String
    self.description = jsonResource["description"] as? String
    self.ordinal = jsonResource["ordinal"] as? Double

  }
}
