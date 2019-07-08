//
//  UserRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import SwiftyJSON

// bookmarksRequest = BookmarksRequest.getAll.filter(by: contentTypes, values: [.screencast, .collection]).sort(by: popularity)

enum BRequest {
  case getAll
  case deleteBookmark(id: String)
  
  var request: Any {
    switch self {
    case .getAll:
      return GetBookmarksRequest()
    case .deleteBookmark(id: let id):
      return DeleteBookmarkRequest(id: id)
    }
  }
}

enum BookmarksRequest: Request {
  typealias Response = [Bookmark]
  
  case getAll
  case deleteBookmark(id: String)
  
  func filter(by: ParameterFilterValue, values: [ContentType]) -> BookmarksRequest? {
    return nil
  }
  
  func sort(by: ParameterSortValue) -> BookmarksRequest? {
    return nil
  }
  
  var method: HTTPMethod {
    switch self {
    case .getAll:
      return .GET
    case .deleteBookmark(id: _):
      return .DELETE
    }
  }
  
  var path: String {
    switch self {
    case .getAll:
      return "/bookmarks"
    case .deleteBookmark(id: let id):
      return "/bookmarks/\(id)"
    }
  }
  
  var additionalHeaders: [String : String]? {
    return nil
  }
  
  var parameters: [Parameter]? {
    return [
    (key: "filter[content_types][]", value: "collection"),
    (key: "filter[content_types][]", value: "screencast"),
    (key: "filter[content_types][]", value: "episode"),
    (key: "filter[content_types][]", value: "article"),
    (key: "filter[content_types][]", value: "product")
    ]
  }
  
  func handle(response: Data) throws -> [Bookmark] {
    
    switch self {
    case .getAll:
      let json = try JSON(data: response)
      let doc = JSONAPIDocument(json)
      let bookmarks = doc.data.compactMap{ Bookmark(resource: $0, metadata: nil) }
      return bookmarks
    case .deleteBookmark(id: _):
      // Should return nothing but a success...??
      return []
    }
  }
}

struct GetBookmarksRequest: Request {
  typealias Response = [Bookmark]
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/bookmarks" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  var parameters: [Parameter]? { return nil }
  
  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap{ Bookmark(resource: $0, metadata: nil) }
    return bookmarks
  }
}

struct DeleteBookmarkRequest: Request {
  typealias Response = [Bookmark]
  
  var method: HTTPMethod { return .DELETE }
  var path: String { return "/bookmarks\(id)" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  private var id: String
  
  init(id: String) {
    self.id = id
  }
  
  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap{ Bookmark(resource: $0, metadata: nil) }
    return bookmarks
  }
}
