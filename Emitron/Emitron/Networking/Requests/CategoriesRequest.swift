//
//  CategoriesRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

enum CategoriesRequest: Request {
  
  typealias Response = [Category]
  
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
      return "/categories"
    }
  }
  
  var additionalHeaders: [String : String]? {
    return nil
  }
  
  func handle(response: Data) throws -> [Category] {
    
    switch self {
    case .getAll:
      let json = try JSON(data: response)
      let doc = JSONAPIDocument(json)
      let categories = doc.data.compactMap{ Category($0, metadata: nil) }
      return categories
    }
  }
}
