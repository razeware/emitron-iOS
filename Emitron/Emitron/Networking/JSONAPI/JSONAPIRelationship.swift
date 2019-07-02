//
//  JSONAPIRelationship.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

public class JSONAPIRelationship {
  
  var meta: [String: Any] = [:]
  var data: [JSONAPIResource] =  []
  var links: [String: URL] = [:]
  var type: String = ""
  
  init() {}
  
  convenience init(_ json: JSON, type: String, parent: JSONAPIDocument?) {
    self.init()
    
    self.type = type
    meta = json["meta"].dictionaryObject ?? [:]
    data = json["data"].arrayValue.map{ JSONAPIResource($0, parent: nil) }
  }
}
