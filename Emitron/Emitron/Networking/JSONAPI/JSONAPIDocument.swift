//
//  JSONAPIDocument.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

class JSONAPIDocument {
  var meta: [String: Any] = [:]
  var included: [JSONAPIResource] = []
  var data: [JSONAPIResource] =  []
  var errors: [JSONAPIError] = []
  var links: [String: URL] = [:]
  
  convenience init(_ json: JSON) {
    self.init()
    
    meta = json["meta"].dictionaryObject ?? [:]
    included = json["included"].arrayValue.map{ JSONAPIResource($0, parent: self) }
    data = json["data"].arrayValue.map{ JSONAPIResource($0, parent: self) }
    errors = json["error"].arrayValue.map{ JSONAPIError($0) }
    
    if let linksDict = json["links"].dictionaryObject {
      for link in linksDict {
        if let strValue = link.value as? String, let url = URL(string: strValue) {
          links[link.key] = url
        }
      }
    }
  }
}

public protocol JSONPrinter {
  func toDict() -> [String: Any]
}

public extension JSONPrinter {
  func toJSONData(_ prettyPrinted: Bool = false) -> Data {
    if prettyPrinted {
      return try! JSONSerialization.data(withJSONObject: toDict(), options: .prettyPrinted)
    }
    
    return try! JSONSerialization.data(withJSONObject: toDict(), options: JSONSerialization.WritingOptions(rawValue: 0))
  }
}
