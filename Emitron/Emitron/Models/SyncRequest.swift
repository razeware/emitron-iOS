// Copyright (c) 2020 Razeware LLC
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

import struct Foundation.Date

struct SyncRequest: Equatable, Codable {
  enum Category: Int, Equatable, Codable {
    case bookmark
    case progress
    case watchStat
  }
  
  enum Synchronisation: Int, Equatable, Codable {
    case createBookmark
    case deleteBookmark
    case deleteProgression
    case markContentComplete
    case updateProgress
    case recordWatchStats
  }
  
  enum Attribute: Equatable {
    case progress(Int)
    case time(Int)
  }
  
  var id: Int64?
  var contentId: Int
  var associatedRecordId: Int?
  var category: Category
  var type: Synchronisation
  var date: Date
  var attributes: [Attribute]
}

extension SyncRequest.Attribute: Encodable {
  enum CodingKeys: CodingKey {
    case progress
    case time
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .progress(let value), .time(let value):
      try container.encode(value, forKey: .progress)
    }
  }
}

extension SyncRequest.Attribute: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    do {
      let progress = try container.decode(Int.self, forKey: .progress)
      self = .progress(progress)
    } catch {
      let time = try container.decode(Int.self, forKey: .time)
      self = .time(time)
    }
  }
}
