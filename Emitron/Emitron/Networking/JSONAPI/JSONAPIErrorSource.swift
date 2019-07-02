//
//  JSONAPIErrorSource.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

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
