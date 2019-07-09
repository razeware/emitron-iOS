/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

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

  var additionalHeaders: [String: String]? {
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
      let bookmarks = doc.data.compactMap { Bookmark(resource: $0, metadata: nil) }
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
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  var parameters: [Parameter]? { return nil }

  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { Bookmark(resource: $0, metadata: nil) }
    return bookmarks
  }
}

struct DeleteBookmarkRequest: Request {
  typealias Response = [Bookmark]

  var method: HTTPMethod { return .DELETE }
  var path: String { return "/bookmarks\(id)" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }

  private var id: String

  init(id: String) {
    self.id = id
  }

  func handle(response: Data) throws -> [Bookmark] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { Bookmark(resource: $0, metadata: nil) }
    return bookmarks
  }
}
