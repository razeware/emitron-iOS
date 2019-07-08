//
//  DomainsRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

enum DomainsRequest: Request {
  
  typealias Response = [Domain]
  
  case getAll
  
  var method: HTTPMethod {
    switch self {
    case .getAll:
      return .GET
    }
  }
  
  var path: String {
    switch self {
    case .getAll:
      return "/domains"
    }
  }
  
  var additionalHeaders: [String : String]? {
    return nil
  }
  
  func handle(response: Data) throws -> [Domain] {
    
    switch self {
    case .getAll:
      let json = try JSON(data: response)
      let doc = JSONAPIDocument(json)
      let domains = doc.data.compactMap{ Domain($0, metadata: nil) }
      return domains
    }
  }
}
