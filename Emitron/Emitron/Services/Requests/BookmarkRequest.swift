//
//  UserRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

struct GetBookmarksRequest: EmitronRequest {
  typealias Response = [Bookmark]
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/contents" }
  var contentType: String { return "application/vnd.api+json; charset=utf-8" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)

    let doc = JSONAPIDocument(json)
    let names = doc.data.compactMap{ $0["name"] }
    print(names)
    let details = doc.data.compactMap{ ContentDetail($0, metadata: nil) }
    return []
  }
}
