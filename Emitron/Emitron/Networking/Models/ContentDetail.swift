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

class ContentDetail {

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
  var videoID: Int?

  var domains: [Domain]?
  var childContents: [ContentSummary]?
  var groups: [Group]?
  var progression: Progression?
  var bookmark: Bookmark?
  var categories: [Category]?
  var url: URL?
  
  init() { }

  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.uri = jsonResource["uri"] as? String
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
    self.bookmarked = jsonResource["bookmarked?"] as? Bool
    self.cardArtworkURL = URL(string: (jsonResource["card_artwork_url"] as? String) ?? "")
    self.technologyTripleString = jsonResource["technology_triple_string"] as? String
    self.contributorString = jsonResource["contributor_string"] as? String
    self.videoID = jsonResource["video_identifier"] as? Int

    for relationship in jsonResource.relationships {
      switch relationship.type {
      case "domains":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let domains = included?.compactMap { Domain($0, metadata: $0.meta) }
        self.domains = domains
      case "groups": // this is where we get our video list
        let ids = relationship.data.compactMap { $0.id }
        let maybeIncluded = jsonResource.parent?.included.filter { ids.contains($0.id) }
        
        var groups: [Group] = []
        if let included = maybeIncluded {
          for resource in included {
            for relationship in resource.relationships {
              if relationship.type == "contents" {
                let contentIds = relationship.data.compactMap { $0.id }
                let included = jsonResource.parent?.included.filter { contentIds.contains($0.id) }
                // This is an ugly hack for now
                let contentSummaries = included?.enumerated().compactMap({ index, summary -> ContentSummary? in
                  ContentSummary(summary, metadata: summary.meta, index: index)
                })
                if let group = Group(resource, metadata: resource.meta, childContents: contentSummaries) {
                  groups.append(group)
                }
              }
            }
          }
        }

        self.groups = groups
      case "progressions":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let progressions = included?.compactMap { Progression($0, metadata: $0.meta) }
        self.progression = progressions?.first
      case "bookmark":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let bookmarks = included?.compactMap { Bookmark(resource: $0, metadata: $0.meta) }
        self.bookmark = bookmarks?.first
      default:
        break
      }
    }
    
    self.url = jsonResource.links["self"]
  }
}
