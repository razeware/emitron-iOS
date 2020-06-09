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

struct ContentsRequest: Request {
  typealias Response = (contents: [Content], cacheUpdate: DataCacheUpdate, totalNumber: Int)

  // MARK: - Properties
  var method: HTTPMethod { .GET }
  var path: String { "/contents" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }

  // MARK: - Internal
  func handle(response: Data) throws -> Response {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let contents = try doc.data.map { try ContentAdapter.process(resource: $0) }
    let cacheUpdate = try DataCacheUpdate.loadFrom(document: doc)
    guard let totalResultCount = doc.meta["total_result_count"] as? Int else {
      throw RWAPIError.responseMissingRequiredMeta(field: "total_result_count")
    }

    return (contents: contents, cacheUpdate: cacheUpdate, totalNumber: totalResultCount)
  }
}

struct ContentDetailsRequest: Request {
  typealias Response = (content: Content, cacheUpdate: DataCacheUpdate)

  // MARK: - Properties
  var method: HTTPMethod { .GET }
  var path: String { "/contents/\(id)" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }
  
  // MARK: - Parameters
  let id: Int

  // MARK: - Internal
  func handle(response: Data) throws -> Response {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let cacheUpdate = try DataCacheUpdate.loadFrom(document: doc)
    let contents = try doc.data.map { try ContentAdapter.process(resource: $0, relationships: cacheUpdate.relationships) }
    
    guard let content = contents.first,
      contents.count == 1 else {
        throw RWAPIError.processingError(nil)
    }
    
    return (content: content, cacheUpdate: cacheUpdate)
  }
}

struct BeginPlaybackTokenRequest: Request {
  typealias Response = String
  
  // MARK: - Properties
  var method: HTTPMethod { .POST }
  var path: String { "/contents/begin_playback" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }
  
  func handle(response: Data) throws -> String {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)

    guard let token = doc.data.first,
      let tokenString = token["video_playback_token"] as? String,
      !tokenString.isEmpty
      else {
        throw RWAPIError.processingError(nil)
    }
    
    return tokenString
  }
}

// This needs to get called every 5 seconds to report usage statistics
struct PlaybackUsageRequest: Request {
  typealias Response = (progression: Progression, cacheUpdate: DataCacheUpdate)
  
  // MARK: - Properties
  var method: HTTPMethod { .POST }
  var path: String { "/contents/\(id)/playback" }
  var additionalHeaders: [String: String] = [:]
  var body: Data? { 
    let json: [String: Any] = [
      "video_playback_token": token,
      "progress": progress,
      "seconds": Constants.videoPlaybackProgressTrackingInterval
    ]
    
    return try? JSONSerialization.data(withJSONObject: json)
  }
  
  // MARK: - Parameters
  let token: String
  let id: Int
  let progress: Int

  // MARK: - Initializers
  init(id: Int, progress: Int, token: String) {
    self.id = id
    self.progress = progress
    self.token = token
  }
  
  func handle(response: Data) throws -> Response {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let progressions = try doc.data.compactMap { try ProgressionAdapter.process(resource: $0) }
    let cacheUpdate = try DataCacheUpdate.loadFrom(document: doc)
    
    guard let progression = progressions.first,
      progressions.count == 1 else {
        throw RWAPIError.responseHasIncorrectNumberOfElements
    }
    
    return (progression: progression, cacheUpdate: cacheUpdate)
  }
}
