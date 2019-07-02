//
//  Domain.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

enum DomainLevel: String {
  case production
  case beta
  case blog
  case archive
  case retired
}

class Domain {
  
  var id: String
  var name: String?
  var slug: String?
  var description: String?
  var level: DomainLevel?
  
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    
    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String
    self.slug = jsonResource["slug"] as? String
    self.description = jsonResource["description"] as? String
    
    if let domainLevel = DomainLevel(rawValue: jsonResource["level"] as? String ?? "") {
      self.level = domainLevel
    }
  }
}
