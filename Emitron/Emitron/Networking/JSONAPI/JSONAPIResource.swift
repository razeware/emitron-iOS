//
//  JSONAPIResource.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

public class JSONAPIResource {
  
  var parent: JSONAPIDocument?
  var id: String = ""
  var type: String = ""
  var relationships: [JSONAPIRelationship] = []
  var attributes: [String: Any] = [:]
  var links: [String: URL] = [:]
  var meta: [String: Any] = [:]
  
  init() {}
  
  public subscript(key: String) -> Any? {
    let value = attributes[key]
    
    return value
  }
  
  convenience init(_ json: JSON, parent: JSONAPIDocument?) {
    
    self.init()
    
    if let doc = parent {
      self.parent = doc
    }
    
    id = json["id"].stringValue
    type = json["type"].stringValue
    
    for relationship in json["relationships"].dictionaryValue {
      relationships.append(JSONAPIRelationship(relationship.value, type: relationship.key, parent: nil))
    }
    
    attributes = json["attributes"].dictionaryObject ?? [:]
    
    if let linksDict = json["links"].dictionaryObject {
      for link in linksDict {
        if let strValue = link.value as? String, let url = URL(string: strValue) {
          links[link.key] = url
        }
      }
    }
    
    meta = json["meta"].dictionaryValue
  }
}

extension JSONAPIResource {
  public subscript<K: CustomStringConvertible, T>(key: K) -> T? {
    return self[key.description] as? T
  }
}
