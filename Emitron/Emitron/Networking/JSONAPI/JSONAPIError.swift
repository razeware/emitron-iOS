//
//  JSONAPIError.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

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
