//
//  ProgressionsRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

enum ProgressionsRequest: Request {
  
  typealias Response = [Progression]
  
  case getAll
  case show(id: String)
  
  var method: HTTPMethod {
    switch self {
    case .getAll:
      return .GET
    case .show(id: _):
      return .GET
    }
  }
  
  var path: String {
    switch self {
    case .getAll:
      return "/progressions"
    case .show(id: let id):
      return "/progressions\(id)"
    }
  }
  
  var additionalHeaders: [String : String]? {
    return nil
  }
  
  func handle(response: Data) throws -> [Progression] {
    
    switch self {
    case .getAll:
      let json = try JSON(data: response)
      let doc = JSONAPIDocument(json)
      let progressions = doc.data.compactMap{ Progression($0, metadata: nil) }
      return progressions
    case .show(id: _):
      let json = try JSON(data: response)
      let doc = JSONAPIDocument(json)
      let progressions = doc.data.compactMap{ Progression($0, metadata: nil) }
      return progressions
    }
  }
}
