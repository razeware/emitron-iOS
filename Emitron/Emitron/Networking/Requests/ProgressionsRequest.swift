// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import SwiftyJSON

struct ProgressionsRequest: Request {
  typealias Response = (progressions: [Progression], cacheUpdate: DataCacheUpdate, totalNumber: Int)

  // MARK: - Properties
  var method: HTTPMethod { .GET }
  var path: String { "/progressions" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }

  // MARK: - Internal
  func handle(response: Data) throws -> Response {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let progressions = try doc.data.map { try ProgressionAdapter.process(resource: $0) }
    let cacheUpdate = try DataCacheUpdate.loadFrom(document: doc)
    guard let totalResultCount = doc.meta["total_result_count"] as? Int else {
      throw RWAPIError.responseMissingRequiredMeta(field: "total_result_count")
    }
    return (progressions: progressions, cacheUpdate: cacheUpdate, totalNumber: totalResultCount)
  }
}

enum ProgressionUpdateData {
  case finished
  case progress(Int)
  
  var jsonAttribute: Dictionary<String, Any>.Element {
    switch self {
    case .finished:
      return ("finished", true)
    case .progress(let progress):
      return ("progress", progress)
    }
  }
}

protocol ProgressionUpdate {
  var contentId: Int { get }
  var data: ProgressionUpdateData { get }
  var updatedAt: Date { get }
}

struct UpdateProgressionsRequest: Request {
  typealias Response = (progressions: [Progression], cacheUpdate: DataCacheUpdate)

  // MARK: - Properties
  var method: HTTPMethod { .POST }
  var path: String { "/progressions/bulk" }
  var additionalHeaders: HTTPHeaders = [:]
  var body: Data? {
    let dataJson = progressionUpdates.map { update in
      [
        "type": "progressions",
        "attributes": [
          "content_id": update.contentId,
          "updated_at": update.updatedAt.iso8601,
          update.data.jsonAttribute.key: update.data.jsonAttribute.value
        ]
      ]
    }
    let json = [
      "data": dataJson
    ]
    
    return try? JSONSerialization.data(withJSONObject: json)
  }
  
  // MARK: - Parameters
  let progressionUpdates: [ProgressionUpdate]

  // MARK: - Internal
  func handle(response: Data) throws -> Response {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let progressions = try doc.data.map { try ProgressionAdapter.process(resource: $0) }
    let cacheUpdate = try DataCacheUpdate.loadFrom(document: doc)
    
    return (progressions: progressions, cacheUpdate: cacheUpdate)
  }
}

struct DeleteProgressionRequest: Request {
  typealias Response = Void

  // MARK: - Properties
  var method: HTTPMethod { .DELETE }
  var path: String { "/progressions/\(id)" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }
  
  // MARK: - Parameters
  let id: Int
  
  // MARK: - Internal
  func handle(response: Data) throws {
    }
}
