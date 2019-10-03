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

struct GetBookmarksRequest: Request {
  typealias Response = [BookmarkModel]
  
  // MARK: - Properties
  var method: HTTPMethod { return .GET }
  var path: String { return "/bookmarks" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  var parameters: [Parameter]? { return nil }
  
  // MARK: - Internal
  func handle(response: Data) throws -> [BookmarkModel] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { BookmarkModel(resource: $0, metadata: nil) }
    return bookmarks
  }
}

struct DeleteBookmarkRequest: Request {
  typealias Response = [BookmarkModel]
  
  // MARK: - Properties
  var method: HTTPMethod { return .DELETE }
  var path: String { return "/bookmarks/\(id)" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  
  private var id: Int
  
  // MARK: - Initializers
  init(id: Int) {
    self.id = id
  }
  
  // MARK: - Internal
  func handle(response: Data) throws -> [BookmarkModel] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { BookmarkModel(resource: $0, metadata: nil) }
    return bookmarks
  }
}

struct BookmarkRequest: Request {
  typealias Response = BookmarkModel
  
  // MARK: - Properties
  var method: HTTPMethod { return .GET }
  var path: String { return "/bookmarks/\(id)" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  private var id: Int
  
  // MARK: - Initializers
  init(id: Int) {
    self.id = id
  }
  
  // MARK: - Internal
  func handle(response: Data) throws -> BookmarkModel {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { BookmarkModel(resource: $0, metadata: nil) }
    guard let bookmark = bookmarks.first,
      bookmarks.count == 1 else {
        throw RWAPIError.processingError(nil)
    }
    
    return bookmark
  }
}

struct MakeBookmark: Request {
  typealias Response = BookmarkModel
  
  // MARK: - Properties
  var method: HTTPMethod { return .POST }
  var path: String { return "/bookmarks" }
  var additionalHeaders: [String: String]?
  var body: Data? {
    let json: [String: Any] =
      ["data":
        ["type": "bookmarks", "relationships":
          ["content":
            ["data":
              ["type": "contents", "id": id]
            ]
          ]
        ]
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    return jsonData
  }
  
  private var id: Int
  
  // MARK: - Initializers
  init(id: Int) {
    self.id = id
  }
  
  // MARK: - Internal
  func handle(response: Data) throws -> BookmarkModel {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let bookmarks = doc.data.compactMap { BookmarkModel(resource: $0, metadata: nil) }
    guard let bookmark = bookmarks.first,
      bookmarks.count == 1 else {
        throw RWAPIError.processingError(nil)
    }
    
    return bookmark
  }
}
