//
//  ContentSummary.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

enum ContentDifficulty: String {
  case beginner
  case intermediate
  case advanced
}

enum ContentType: String {
  case collection
  case episode
  case screencast
  case article
  case product
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
    self.bookmarked = jsonResource["bookmarked"] as? Bool
    self.cardArtworkURL = URL(string: (jsonResource["card_artwork_url"] as? String) ?? "")
    self.technologyTripleString = jsonResource["technology_triple_string"] as? String
    self.contributorString = jsonResource["contributor_string"] as? String
  }
}
