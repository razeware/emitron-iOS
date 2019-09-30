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

struct ContentsRequest: Request {
  typealias Response = (contents: [ContentSummaryModel], totalNumber: Int)

  // MARK: - Properties
  var method: HTTPMethod { return .GET }
  var path: String { return "/contents" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }

  // MARK: - Internal
  func handle(response: Data) throws -> (contents: [ContentSummaryModel], totalNumber: Int) {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let contents = doc.data.compactMap { ContentSummaryModel($0, metadata: nil) }
    return (contents: contents, totalNumber: doc.meta["total_result_count"] as? Int ?? 0)
  }
}

struct ContentDetailsRequest: Request {
  typealias Response = ContentDetailsModel

  // MARK: - Properties
  var method: HTTPMethod { return .GET }
  var path: String { return "/contents/\(id)" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  private var id: Int

  // MARK: - Initializers
  init(id: Int) {
    self.id = id
  }

  // MARK: - Internal
  func handle(response: Data) throws -> ContentDetailsModel {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let content = doc.data.compactMap { ContentDetailsModel($0, metadata: nil) }
    guard let contentSummary = content.first,
      content.count == 1 else {
        throw RWAPIError.processingError(nil)
    }
    
    return contentSummary
  }
}

struct BeginPlaybackTokenRequest: Request {
  typealias Response = String
  
  // MARK: - Properties
  var method: HTTPMethod { return .POST }
  var path: String { return "/contents/begin_playback" }
  var additionalHeaders: [String: String]?
  var body: Data? { return nil }
  
  func handle(response: Data) throws -> String {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)

    guard let token = doc.data.first,
    let tokenString = token["video_playback_token"] as? String, !tokenString.isEmpty else {
        throw RWAPIError.processingError(nil)
    }
    
    return tokenString
  }
}

// This needs to get called every 5 seconds to report usage statistics
struct PlaybackUsageRequest: Request {
  typealias Response = ProgressionModel
  
  // MARK: - Properties
  var method: HTTPMethod { return .POST }
  var path: String { return "/contents/\(id)/playback" }
  var additionalHeaders: [String: String]?
  var body: Data? { 
    let json: [String: Any] = ["video_playback_token": token, "progress": progress, "seconds": seconds]
    return try? JSONSerialization.data(withJSONObject: json)
  }
  
  private var token: String
  private var id: Int
  private var progress: Int
  private var seconds = 5
  
  // MARK: - Initializers
  init(id: Int, progress: Int, token: String) {
    self.id = id
    self.progress = progress
    self.token = token
  }
  
  func handle(response: Data) throws -> ProgressionModel {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let playbackProgressContent = doc.data.compactMap { ProgressionModel($0, metadata: nil) }
    
    guard let progress = playbackProgressContent.first,
      playbackProgressContent.count == 1 else {
        throw RWAPIError.processingError(nil)
    }
    
    return progress
  }
}


