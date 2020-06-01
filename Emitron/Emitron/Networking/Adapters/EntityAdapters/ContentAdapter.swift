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

import struct Foundation.URL

struct ContentAdapter: EntityAdapter {
  static func process(resource: JSONAPIResource, relationships: [EntityRelationship] = []) throws -> Content {
    guard resource.entityType == .content else { throw EntityAdapterError.invalidResourceTypeForAdapter }
    
    guard let uri = resource.attributes["uri"] as? String,
      let name = resource.attributes["name"] as? String,
      let descriptionHtml = resource.attributes["description"] as? String,
      let descriptionPlainText = resource.attributes["description_plain_text"] as? String,
      let releasedAtString = resource.attributes["released_at"] as? String,
      let releasedAt = releasedAtString.iso8601,
      let free = resource.attributes["free"] as? Bool,
      let professional = resource.attributes["professional"] as? Bool,
      let contentTypeString = resource.attributes["content_type"] as? String,
      let contentType = ContentType(string: contentTypeString),
      let duration = resource.attributes["duration"] as? Int,
      let technologyTriple = resource.attributes["technology_triple_string"] as? String,
      let contributors = resource.attributes["contributor_string"] as? String
      else {
        throw EntityAdapterError.invalidOrMissingAttributes
    }
    var difficulty = ContentDifficulty.allLevels
    if let difficultyString = resource.attributes["difficulty"] as? String {
      if let parsedDifficulty = ContentDifficulty(string: difficultyString) {
        difficulty = parsedDifficulty
      } else {
        throw EntityAdapterError.invalidOrMissingAttributes
      }
    }
    
    var cardArtworkUrl: URL?
    if let cardArtworkUrlString = resource.attributes["card_artwork_url"] as? String {
      cardArtworkUrl = URL(string: cardArtworkUrlString)
    }
    
    let group = relationships.first { relationship in
      relationship.from.type == .group
        && relationship.to.id == resource.id
        && relationship.to.type == .content
    }
    let groupId = group?.from.id
    
    return Content(id: resource.id,
                   uri: uri,
                   name: name,
                   descriptionHtml: descriptionHtml,
                   descriptionPlainText: descriptionPlainText,
                   releasedAt: releasedAt,
                   free: free,
                   professional: professional,
                   difficulty: difficulty,
                   contentType: contentType,
                   duration: duration,
                   videoIdentifier: resource.attributes["video_identifier"] as? Int,
                   cardArtworkUrl: cardArtworkUrl,
                   technologyTriple: technologyTriple,
                   contributors: contributors,
                   groupId: groupId,
                   ordinal: resource.attributes["ordinal"] as? Int)
  }
}
