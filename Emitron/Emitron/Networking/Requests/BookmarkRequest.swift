//
//  UserRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

enum AttachmentRequest: Request {
  typealias Response = [Attachment]
  
  
}

struct GetBookmarksRequest: Request {
  typealias Response = [Bookmark]
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/bookmarks" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  var parameters: Parameters? { return nil }
  
  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap{ Bookmark(resource: $0, metadata: nil) }
    return bookmarks
  }
}
