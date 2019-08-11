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

class ContentDetailModel {

  // MARK: - Properties
  private(set) var id: Int = 0
  private(set) var uri: String = ""
  private(set) var name: String = ""
  private(set) var description: String = ""
  private(set) var releasedAt: Date
  private(set) var free: Bool = false
  private(set) var difficulty: ContentDifficulty = .none
  private(set) var contentType: ContentType = .none
  private(set) var duration: Int = 0
  private(set) var popularity: Double = 0.0
  private(set) var bookmarked: Bool = false
  private(set) var cardArtworkURL: URL?
  private(set) var technologyTripleString: String = ""
  private(set) var contributorString: String = ""
  private(set) var videoID: Int = 0

  private(set) var domains: [DomainModel] = []
  private(set) var childContents: [ContentSummaryModel] = []
  private(set) var groups: [GroupModel] = []
  private(set) var progression: ProgressionModel?
  private(set) var bookmark: BookmarkModel?
  private(set) var categories: [CategoryModel] = []
  private(set) var url: URL?

  // MARK: - Initializers
  init?(_ jsonResource: JSONAPIResource,
        metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.uri = jsonResource["uri"] as? String ?? ""
    self.name = jsonResource["name"] as? String ?? ""
    self.description = jsonResource["description"] as? String ?? ""

    if let releasedAtStr = jsonResource["released_at"] as? String {
      self.releasedAt = DateFormatter.apiDateFormatter.date(from: releasedAtStr) ?? Date()
    } else {
      self.releasedAt = Date()
    }

    self.free = jsonResource["free"] as? Bool ?? false

    if let difficulty = ContentDifficulty(rawValue: jsonResource["difficulty"] as? String ?? "") {
      self.difficulty = difficulty
    }

    if let type = ContentType(rawValue: jsonResource["content_type"] as? String ?? "") {
      self.contentType = type
    }

    self.duration = jsonResource["duration"] as? Int ?? 0
    self.popularity = jsonResource["popularity"] as? Double ?? 0.0
    self.bookmarked = jsonResource["bookmarked?"] as? Bool ?? false
    self.cardArtworkURL = URL(string: (jsonResource["card_artwork_url"] as? String) ?? "")
    self.technologyTripleString = jsonResource["technology_triple_string"] as? String ?? ""
    self.contributorString = jsonResource["contributor_string"] as? String ?? ""
    
    //TODO: Get the actual videoIdentifier
    self.videoID = Int(self.uri.digits) ?? 0

    for relationship in jsonResource.relationships {
      switch relationship.type {
      case "domains":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let domains = included?.compactMap { DomainModel($0, metadata: $0.meta) }
        self.domains = domains ?? []
      
      //TODO: This will be improved when the API returns enough info to render the video listing, currently
      // picking up the bits and pieces of info from separate parts
      case "groups": // this is where we get our video list
        let ids = relationship.data.compactMap { $0.id }
        let maybeIncluded = jsonResource.parent?.included.filter { ids.contains($0.id) }
        
        var groups: [GroupModel] = []
        if let included = maybeIncluded {
          for resource in included {
            for relationship in resource.relationships where relationship.type == "contents" {
              let contentIds = relationship.data.compactMap { $0.id }
              let included = jsonResource.parent?.included.filter { contentIds.contains($0.id) }
              // This is an ugly hack for now
              let contentSummaries = included?.enumerated().compactMap({ index, summary -> ContentSummaryModel? in
                ContentSummaryModel(summary, metadata: summary.meta, index: index)
              })
              if let group = GroupModel(resource, metadata: resource.meta, childContents: contentSummaries ?? []) {
                groups.append(group)
              }
            }
          }
        }

        self.groups = groups
      case "progression":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let progressions = included?.compactMap { ProgressionModel($0, metadata: $0.meta) }
        self.progression = progressions?.first
      case "bookmark":
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { _ in !ids.contains(0) }
        let bookmarks = included?.compactMap { BookmarkModel(resource: $0, metadata: $0.meta) }
        self.bookmark = bookmarks?.first
      default:
        break
      }
    }
    
    self.url = jsonResource.links["self"]
  }
  
  /// Convenience initializer to transform core data **Contents** into a **ContentDetailModel**
  ///
  /// - parameters:
  ///   - content: core data entity to transform into domain model
  init(_ content: Contents) {
    self.id = content.id.intValue
    self.name = content.name
    self.uri = content.uri
    self.description = content.desc
    self.releasedAt = content.releasedAt
    self.free = content.free
    self.difficulty = ContentDifficulty(rawValue: content.difficulty) ?? .none
    self.contentType = ContentType(rawValue: content.contentType) ?? .none
    self.duration = content.duration.intValue
    self.bookmarked = content.bookmarked
    self.popularity = content.popularity
    self.cardArtworkURL = content.cardArtworkUrl
    self.technologyTripleString = content.technologyTripleString
    self.contributorString = content.contributorString
    self.videoID = content.videoID.intValue
  }
}

extension ContentDetailModel {
  static var test: ContentDetailModel {
    do {
      let fileURL = Bundle.main.url(forResource: "ContentDetailsModelTest", withExtension: "json")
      let data = try Data(contentsOf: fileURL!)
      let json = try JSON(data: data)
    
      let document = JSONAPIDocument(json)
      let resource = JSONAPIResource(json, parent: document)
      return ContentDetailModel(resource, metadata: nil)!
    } catch {
      let resource = JSONAPIResource()
      return ContentDetailModel(resource, metadata: nil)!
    }
  }
}
