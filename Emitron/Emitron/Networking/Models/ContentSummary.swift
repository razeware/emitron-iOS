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

extension String {
  var digits: String {
    return components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()
  }
}

class ContentSummary {

  var id: String?
  var uri: String?
  var name: String?
  var description: String?
  var releasedAt: Date?
  var free: Bool?
  var difficulty: ContentDifficulty?
  var contentType: ContentType?
  var duration: Double?
  var popularity: Double?
  var bookmarked: Bool?
  var cardArtworkURL: URL?
  var technologyTripleString: String?
  var contributorString: String?
  var index: Int = 0
  var videoID: Int = 0

  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?, index: Int) {

    self.id = jsonResource.id
    self.index = index
    
    self.uri = jsonResource["uri"] as? String
    
    //let strVideoID = "\(self.uri?.split(separator: "/", maxSplits: 5, omittingEmptySubsequences: true).last!)"
    self.videoID = Int(self.uri!.digits) ?? 0
    
    self.name = jsonResource["name"] as? String
    self.description = jsonResource["description"] as? String

    if let releasedAtStr = jsonResource["released_at"] as? String {
      self.releasedAt = DateFormatter.apiDateFormatter.date(from: releasedAtStr) ?? Date()
    } else {
      self.releasedAt = Date()
    }

    self.free = jsonResource["free"] as? Bool

    if let difficulty = ContentDifficulty(rawValue: jsonResource["difficulty"] as? String ?? "") {
      self.difficulty = difficulty
    }

    if let type = ContentType(rawValue: jsonResource["content_type"] as? String ?? "") {
      self.contentType = type
    }

    self.duration = jsonResource["duration"] as? Double
    self.popularity = jsonResource["popularity"] as? Double
    self.bookmarked = jsonResource["bookmarked"] as? Bool
    self.cardArtworkURL = URL(string: (jsonResource["card_artwork_url"] as? String) ?? "")
    self.technologyTripleString = jsonResource["technology_triple_string"] as? String
    self.contributorString = jsonResource["contributor_string"] as? String
  }
}
