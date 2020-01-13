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

struct ProgressionsRequest: Request {
  typealias Response = (progressions: [Progression], cacheUpdate: DataCacheUpdate, totalNumber: Int)

  // MARK: - Properties
  var method: HTTPMethod { return .GET }
  var path: String { return "/progressions" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }

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

// TODO: WTF is this??!
struct UpdateProgressionsRequeest: Request {
  typealias Response = Progression

  // MARK: - Properties
  var method: HTTPMethod { return .POST }
  var path: String { return "/progressions/bulk" }
  var additionalHeaders: [String: String]?
  var body: Data? {
    let json: [String: Any] =
      ["progressions":
        [[
          "content_id": id,
          "progress": 10,
          "updated_at": "2019-06-18T14:16:53.689"
          ],
         [
          "content_id": 67890,
          "finished": true,
          "updated_at": "2019-06-18T14:16:53.689"
          ]]
      ]
        
    return try? JSONSerialization.data(withJSONObject: json)
  }

  private var id: Int
  private var progress: Int
  private var finished: Bool = false
  private var updatedAt: Date

  // MARK: - Initializers
  init(id: Int, progress: Int, finished: Bool, updatedAt: Date) {
    self.id = id
    self.progress = progress
    self.finished = finished
    self.updatedAt = updatedAt
  }

  // MARK: - Internal
  func handle(response: Data) throws -> Progression {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let progressions = try doc.data.map { try ProgressionAdapter.process(resource: $0) }
    guard let progression = progressions.first else {
      throw RWAPIError.processingError(nil)
    }
    return progression
  }
}
