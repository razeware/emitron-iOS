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
import GRDB

struct Content: Codable, FetchableRecord, TableRecord, PersistableRecord {
  enum Difficulty: Int, Codable {
    case beginner, intermediate, advanced
    
    init(contentDifficulty: ContentDifficulty) {
      switch contentDifficulty {
      case .beginner:
        self = .beginner
      case .intermediate:
        self = .intermediate
      case .advanced:
        self = .advanced
      default:
        self = .beginner
      }
    }
  }
  
  enum ContType: Int, Codable {
    case collection, episode, screencast, article, product
    
    init(contentType: ContentType) {
      switch contentType {
      case .article:
        self = .article
      case .collection:
        self = .collection
      case .episode:
        self = .episode
      case .product:
        self = .product
      case .screencast:
        self = .screencast
      default:
        self = .article
      }
    }
  }
  
  var id: Int
  var uri: String
  var name: String
  var descriptionHtml: String?
  var descriptionPlainText: String?
  var releasedAt: Date
  var free: Bool
  var professional: Bool
  var difficulty: Difficulty
  var contentType: ContType
  var duration: Int
  var videoIdentifier: Int?
  var cardArtworkUrl: URL?
  var technologyTriple: String?
  var contributors: String?
  var groupId: Int?
}

// MARK: Associations
extension Content {
  static let bookmark = hasOne(Bookmark.self)
  static let progression = hasOne(Progression.self)
  static let contentCategories = hasMany(ContentCategory.self)
  static let categories = hasMany(Category.self, through: contentCategories, using: ContentCategory.category)
  static let contentDomains = hasMany(ContentDomain.self)
  static let domains = hasMany(Domain.self, through: contentDomains, using: ContentDomain.domain)
  static let groups = hasMany(Group.self)
  static let group = belongsTo(Group.self)
  static let parentContent = hasOne(Content.self, through: group, using: Group.content)
  static let childContents = hasMany(Content.self, through: groups, using: Group.contents)
  static let download = hasOne(Download.self)
}

// MARK: Relationship Requests
extension Content {
  var bookmark: QueryInterfaceRequest<Bookmark> {
    request(for: Content.bookmark)
  }
  
  var progression: QueryInterfaceRequest<Progression> {
    request(for: Content.progression)
  }
  
  var contentCategories: QueryInterfaceRequest<ContentCategory> {
    request(for: Content.contentCategories)
  }
  
  var categories: QueryInterfaceRequest<Category> {
    request(for: Content.categories)
  }
  
  var contentDomains: QueryInterfaceRequest<ContentDomain> {
    request(for: Content.contentDomains)
  }
  
  var domains: QueryInterfaceRequest<Domain> {
    request(for: Content.domains)
  }
  
  var groups: QueryInterfaceRequest<Group> {
    request(for: Content.groups)
  }
  
  var parentContent: QueryInterfaceRequest<Content> {
    request(for: Content.parentContent)
  }
  
  var childContents: QueryInterfaceRequest<Content> {
    request(for: Content.childContents)
  }
  
  var download: QueryInterfaceRequest<Download> {
    request(for: Content.download)
  }
}

// MARK: - Interface with ContentDetailsModel
extension Content {
  init(contentDetailsModel: ContentDetailsModel) {
    id = contentDetailsModel.id
    uri = contentDetailsModel.uri
    name = contentDetailsModel.name
    descriptionHtml = contentDetailsModel.desc
    // TODO: Fix this...
    descriptionPlainText = ""
    releasedAt = contentDetailsModel.releasedAt
    free = contentDetailsModel.free
    professional = contentDetailsModel.professional
    difficulty = Difficulty(contentDifficulty: contentDetailsModel.difficulty ?? .beginner)
    contentType = ContType(contentType: contentDetailsModel.contentType ?? .article)
    duration = contentDetailsModel.duration
    videoIdentifier = contentDetailsModel.videoID
    cardArtworkUrl = contentDetailsModel.cardArtworkURL
    technologyTriple = contentDetailsModel.technologyTripleString
    contributors = contentDetailsModel.contributorString
  }
}
