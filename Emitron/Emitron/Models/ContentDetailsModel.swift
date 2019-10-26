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

enum ContentRelationship: String {
  case domains // When relating multiple domains, used when adding relationships from the resource itself
  case domain // When only relating one domain, used when adding relationships from DomainModel
  case groups
  case progression
  case bookmark
  case childContents = "child_contents"
  case none
}

protocol ContentRelatable {
  var type: ContentRelationship { get }
}

class ContentDetailsModel {

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
  private(set) var cardArtworkURL: URL?
  private(set) var technologyTripleString: String = ""
  private(set) var contributorString: String = ""
  private(set) var videoID: Int?
  private(set) var index: Int?
  private(set) var professional: Bool = false

  private(set) var childContents: [ContentDetailsModel] = []
  private(set) var groups: [GroupModel] = []
  private(set) var categories: [CategoryModel] = []
  private(set) var url: URL?

  var parentContent: ContentDetailsModel?
  var isDownloaded = false
  var progression: ProgressionModel?
  var progressionId: Int?
  var bookmark: BookmarkModel?
  var shouldCancel = false
  var domains: [DomainModel] = []
  var domainIDs: [Int] = []
  
  var parentContentId: Int?
  
  var bookmarkId: Int? {
    bookmark?.id
  }
  var bookmarked: Bool {
    bookmark != nil
  }

  // If content is a video collectiona and it doesn't have groups, then it needs to be fully loaded
  var needsDetails: Bool {
    contentType == .collection && !(groups.count > 0)
  }

  // MARK: - Initializers
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.index = jsonResource["ordinal"] as? Int
    self.uri = jsonResource["uri"] as? String ?? ""
    self.name = jsonResource["name"] as? String ?? ""
    self.description = jsonResource["description_plain_text"] as? String ?? ""

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
    self.professional = jsonResource["professional"] as? Bool ?? false
    self.cardArtworkURL = URL(string: (jsonResource["card_artwork_url"] as? String) ?? "")
    self.technologyTripleString = jsonResource["technology_triple_string"] as? String ?? ""
    self.contributorString = jsonResource["contributor_string"] as? String ?? ""
    self.videoID = jsonResource["video_identifier"] as? Int
    self.url = jsonResource.links["self"]
    
    for relationship in jsonResource.relationships where relationship.type == "domains" {
      let ids = relationship.data.compactMap { $0.id }
      self.domainIDs = ids
    }
  }
  
  // Bookmarks and progressionos can be full-fledged models when we create the relationships, so we don't want a circular dependency between them
  
  func addRelationships(for contentRelatable: [ContentRelatable]) {
    for relationship in contentRelatable {
      switch relationship.type {
      case .bookmark:
        if let bookmark = relationship as? BookmarkModel {
          self.bookmark = bookmark
        }
      case .progression:
        if let progression = relationship as? ProgressionModel {
          self.progression = progression
        }
      case .domain:
        if let domain = relationship as? DomainModel, !domains.contains(domain) {
          self.domains.append(domain)
        }
      default:
        print("Don't have a two way binding for this model yet...")
      }
    }
  }
  
  func addRelationships(for jsonResource: JSONAPIResource) {
    
    for relationship in jsonResource.relationships {
      let relatinoshipType = ContentRelationship(rawValue: relationship.type) ?? .none
      
      switch relatinoshipType {
      case .domains:
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let domains = included?.compactMap { DomainModel($0, metadata: $0.meta) }

        // If a domain comes through that doesn't match any of the domains we have, make a new domain request.
        self.domainIDs = ids
        self.domains = domains ?? []

      //TODO: This will be improved when the API returns enough info to render the video listing, currently
      // picking up the bits and pieces of info from separate parts
      case .groups: // this is where we get our video list
        let ids = relationship.data.compactMap { $0.id }
        let maybeIncluded = jsonResource.parent?.included.filter { ids.contains($0.id) }

        var groups: [GroupModel] = []
        if let included = maybeIncluded {
          for resource in included {
            for relationship in resource.relationships where relationship.type == "contents" {
              let contentIds = relationship.data.compactMap { $0.id }
              let included = jsonResource.parent?.included.filter { contentIds.contains($0.id) }
              // This is an ugly hack for now
              let contentDetails = included?.enumerated().compactMap({ summary -> ContentDetailsModel? in
                guard let content = ContentDetailsModel(summary.element, metadata: [:]) else { return nil }
                content.addRelationships(for: summary.element)
                content.parentContent = self
                return content
              })

              if let group = GroupModel(resource, metadata: resource.meta, childContents: contentDetails ?? []) {
                groups.append(group)
              }
            }
          }
        }

        self.groups = groups
      case .progression where self.progression == nil:
        let ids = relationship.data.compactMap { $0.id }
        self.progressionId = ids.first
        let included = jsonResource.parent?.included.filter { ids.contains($0.id) }
        let progressions = included?.compactMap { ProgressionModel($0, metadata: $0.meta) }
        self.progression = progressions?.first
      case .bookmark where self.bookmark == nil:
        let ids = relationship.data.compactMap { $0.id }
        let included = jsonResource.parent?.included.filter { _ in !ids.contains(0) }
        let bookmarks = included?.compactMap { BookmarkModel(resource: $0, metadata: $0.meta) }
        self.bookmark = bookmarks?.first
        
        // We can simply make a Bookmark with just an ID
        if let id = ids.first, self.bookmark != nil {
          self.bookmark = BookmarkModel(id: id)
        }
      default:
        break
      }
    }
  }

  init(summaryModel: ContentSummaryModel) {
    self.id = summaryModel.id
    self.name = summaryModel.name
    self.uri = summaryModel.uri
    self.description = summaryModel.description
    self.releasedAt = summaryModel.releasedAt
    self.free = summaryModel.free
    self.difficulty = summaryModel.difficulty
    self.contentType = summaryModel.contentType
    self.duration = summaryModel.duration
    self.popularity = summaryModel.popularity
    self.cardArtworkURL = summaryModel.cardArtworkURL
    self.technologyTripleString = summaryModel.technologyTripleString
    self.contributorString = summaryModel.contributorString
    self.videoID = summaryModel.videoID
    self.domainIDs = summaryModel.domainIDs
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
    self.popularity = content.popularity
    self.cardArtworkURL = content.cardArtworkUrl
    self.technologyTripleString = content.technologyTripleString
    self.contributorString = content.contributorString
    self.videoID = content.videoID?.intValue
  }

  /// Convenience initializer to transform UIDocument **ContentsData** into a **ContentDetailModel**
  ///
  /// - parameters:
  ///   - content: core data entity to transform into domain model
  init(_ content: ContentsData) {
    self.id = content.id ?? 0
    self.name = content.name
    self.uri = content.uri
    self.description = content.contentDescription
    self.releasedAt = content.releasedAt
    self.free = content.free
    self.difficulty = ContentDifficulty(rawValue: content.difficulty) ?? .none
    self.contentType = ContentType(rawValue: content.contentType) ?? .none
    self.duration = content.duration
    self.popularity = content.popularity
    self.cardArtworkURL = content.cardArtworkURL
    self.technologyTripleString = content.technologyTripleString
    self.contributorString = content.contributorString
    self.videoID = content.videoID
    self.parentContentId = content.parentContentId
  }
}

extension ContentDetailsModel {
  static var test: ContentDetailsModel {
    do {
      let fileURL = Bundle.main.url(forResource: "ContentDetailsModelTest", withExtension: "json")
      let data = try Data(contentsOf: fileURL!)
      let json = try JSON(data: data)

      let document = JSONAPIDocument(json)
      let resource = JSONAPIResource(json, parent: document)
      return ContentDetailsModel(resource, metadata: nil)!
    } catch {
      let resource = JSONAPIResource()
      return ContentDetailsModel(resource, metadata: nil)!
    }
  }
}

extension ContentDetailsModel {

  var isInCollection: Bool {
    return contentType == .collection || contentType == .episode
  }
}
