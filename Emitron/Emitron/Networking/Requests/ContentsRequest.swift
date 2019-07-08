//
//  ContentsRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ContentsRequest: Request {
  typealias Response = [ContentDetail]
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/contents" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  func handle(response: Data) throws -> [ContentDetail] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let contents = doc.data.compactMap{ ContentDetail($0, metadata: nil) }
    return contents
  }
}
