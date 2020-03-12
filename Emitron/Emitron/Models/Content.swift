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

struct Content: Codable {
  var id: Int
  var uri: String
  var name: String
  var descriptionHtml: String
  var descriptionPlainText: String
  var releasedAt: Date
  var free: Bool
  var professional: Bool
  var difficulty: ContentDifficulty
  var contentType: ContentType
  var duration: Int
  var videoIdentifier: Int?
  var cardArtworkUrl: URL?
  var technologyTriple: String
  var contributors: String
  var groupId: Int?
  var ordinal: Int?
}

extension Content: Equatable {
  // We override this function because SQLite doesn't store dates to the same accuracy as Date
  static func == (lhs: Content, rhs: Content) -> Bool {
    lhs.id == rhs.id &&
      lhs.uri == rhs.uri &&
      lhs.name == rhs.name &&
      lhs.descriptionHtml == rhs.descriptionHtml &&
      lhs.descriptionPlainText == rhs.descriptionPlainText &&
      lhs.releasedAt.equalEnough(to: rhs.releasedAt) &&
      lhs.free == rhs.free &&
      lhs.professional == rhs.professional &&
      lhs.difficulty == rhs.difficulty &&
      lhs.contentType == rhs.contentType &&
      lhs.duration == rhs.duration &&
      lhs.videoIdentifier == rhs.videoIdentifier &&
      lhs.cardArtworkUrl == rhs.cardArtworkUrl &&
      lhs.technologyTriple == rhs.technologyTriple &&
      lhs.contributors == rhs.contributors &&
      lhs.groupId == rhs.groupId
  }
}

extension Content {
  func update(from other: Content) -> Content {
    Content(id: other.id,
            uri: other.uri,
            name: other.name,
            descriptionHtml: other.descriptionHtml,
            descriptionPlainText: other.descriptionPlainText,
            releasedAt: other.releasedAt,
            free: other.free,
            professional: other.professional,
            difficulty: other.difficulty,
            contentType: other.contentType,
            duration: other.duration,
            videoIdentifier: other.videoIdentifier,
            cardArtworkUrl: other.cardArtworkUrl,
            technologyTriple: other.technologyTriple,
            contributors: other.contributors,
            groupId: other.groupId ?? self.groupId,
            ordinal: other.ordinal)
  }
}
