//
//  JSONAPIDocument.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

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

public class JSONAPILink {
  
}

public class JSONAPIError {
  var id: String = ""
  var links: [String: URL] = [:]
  var status: String = ""
  var code: String = ""
  var title: String = ""
  var detail: String = ""
  var source: JSONAPIErrorSource?
  var meta: [String: Any] = [:]
  
  init() {}
  
  convenience init(_ json: JSON) {
    self.init()
    
    id = json["id"].stringValue
    
    if let linksDict = json["links"].dictionaryObject {
      for link in linksDict {
        if let strValue = link.value as? String, let url = URL(string: strValue) {
          links[link.key] = url
        }
      }
    }
    
    status = json["status"].stringValue
    code = json["code"].stringValue
    title = json["title"].stringValue
    detail = json["detail"].stringValue
    source = JSONAPIErrorSource(json["source"])
    meta = json["meta"].dictionaryValue
  }
}

public class JSONAPIErrorSource {
  var pointer: String = ""
  var parameter: String = ""
  
  init() {}
  
  convenience init(_ json: JSON) {
    self.init()
    
    pointer = json["pointer"].stringValue
    parameter = json["parameter"].stringValue
  }
}

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
