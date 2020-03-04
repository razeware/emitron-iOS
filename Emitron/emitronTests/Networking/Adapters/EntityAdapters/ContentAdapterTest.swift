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

import XCTest
import SwiftyJSON
@testable import Emitron

class ContentAdapterTest: XCTestCase {
  let sampleResource: JSON = [
    "id": "12",
    "type": "contents",
    "attributes": [
      "uri": "rw://betamax/videos/12",
      "name": "Some kind of content",
      "description": "HTML Description",
      "description_plain_text": "PLAIN TEXT",
      "released_at": "2020-01-01T12:00:00.000Z",
      "free": true,
      "difficulty": "advanced",
      "content_type": "collection",
      "duration": 342,
      "popularity": 727.0,
      "card_artwork_url": "https://example.com/card_artwork.png",
      "technology_triple_string": "Swift 5, iOS 13.0 Beta, Xcode 11.0 Beta",
      "contributor_string": "Katie Collins & Jessy Catterwaul",
      "video_identifier": 2546,
      "ordinal": 13,
      "professional": true,
      "parent_name": "something here"
    ],
    "relationships": [
      "domains": [
        "data": [
          [
            "id": "1",
            "type": "domains"
          ]
        ]
      ],
      "child_contents": [
        "meta": [
          "count": 0
        ]
      ],
      "progression": [
        "data": NSNull()
      ],
      "bookmark": [
        "data": NSNull()
      ],
      "groups": [
        "data": [
        ]
      ],
      "categories": [
        "data": [
          [
            "id": "158",
            "type": "categories"
          ]
        ]
      ]
    ],
    "links": [
      "self": "http://api.raywenderlich.com/api/contents/1320588-machine-learning-in-ios-introduction",
      "video_stream": "http://api.raywenderlich.com/api/videos/2546/stream",
      "video_download": "http://api.raywenderlich.com/api/videos/2546/download"
    ]
  ]
  
  let relationships = [
    EntityRelationship(name: "", from: EntityIdentity(id: 1235, type: .group), to: EntityIdentity(id: 11, type: .content)),
    EntityRelationship(name: "", from: EntityIdentity(id: 1234, type: .group), to: EntityIdentity(id: 12, type: .content))
  ]
  
  func makeJsonAPIResource(for dict: JSON) throws -> JSONAPIResource {
    let json: JSON = [
      "data": [
        dict
      ]
    ]
    
    let document = JSONAPIDocument(json)
    return document.data.first!
  }

  func testValidResourceProcessedCorrectly() throws {
    let resource = try makeJsonAPIResource(for: sampleResource)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    
    XCTAssertEqual(12, content.id)
    XCTAssertEqual("Some kind of content", content.name)
    XCTAssertEqual("HTML Description", content.descriptionHtml)
    XCTAssertEqual("PLAIN TEXT", content.descriptionPlainText)
    let cmpts = DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2020, month: 1, day: 1, hour: 12, minute: 0, second: 0)
    XCTAssertEqual(Calendar.current.date(from: cmpts), content.releasedAt)
    XCTAssert(content.free)
    XCTAssert(content.professional)
    XCTAssertEqual(.collection, content.contentType)
    XCTAssertEqual(342, content.duration)
    let url = URL(string: "https://example.com/card_artwork.png")!
    XCTAssertEqual(url, content.cardArtworkUrl)
    XCTAssertEqual("Swift 5, iOS 13.0 Beta, Xcode 11.0 Beta", content.technologyTriple)
    XCTAssertEqual("Katie Collins & Jessy Catterwaul", content.contributors)
    XCTAssertEqual(13, content.ordinal)
    XCTAssertEqual(.advanced, content.difficulty)
    XCTAssertEqual(1234, content.groupId)
    XCTAssertEqual(2546, content.videoIdentifier)
  }
  
  func testMissingUriThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "uri")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingNameThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "name")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingDescriptionThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "description")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingPlainTextDescriptionThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "description_plain_text")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidReleasedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["released_at"] = "this is not a valid date"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingFreeThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "free")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingProfessionalThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "professional")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidContentTypeThrows() throws {
    var sample = sampleResource
    sample["attributes"]["content_type"] = "movie"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingDurationThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "duration")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingTechnologyTripleThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "technology_triple_string")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingContributorsThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "contributor_string")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingDifficultyIsAcceptableAndDefaultsToAllLevels() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "difficulty")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertEqual(.allLevels, content.difficulty)
  }
  
  func testInvalidDifficultyThrows() throws {
    var sample = sampleResource
    sample["attributes"]["difficulty"] = "super-hard"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ContentAdapter.process(resource: resource, relationships: relationships)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidCardArtworkUrlIsAcceptable() throws {
    var sample = sampleResource
    sample["attributes"]["card_artwork_url"] = JSON(NSNull())
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.cardArtworkUrl)
  }
  
  func testMissingGroupIsAcceptable() throws {
    let relationships = Array(self.relationships.dropLast())
    let resource = try makeJsonAPIResource(for: sampleResource)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.groupId)
  }
  
  func testFirstRelationshipIsChosenToDetermineGroup() throws {
    let relationships = [EntityRelationship(name: "", from: EntityIdentity(id: 4321, type: .group), to: EntityIdentity(id: 12, type: .content))] + self.relationships
    
    let resource = try makeJsonAPIResource(for: sampleResource)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertEqual(4321, content.groupId)
  }
  
  func testNullOrdinalIsAcceptable() throws {
    var sample = sampleResource
    sample["attributes"]["ordinal"] = JSON(NSNull())
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.ordinal)
  }
  
  func testMissingOrdinalIsAcceptable() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "ordinal")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.ordinal)
  }
  
  func testNullVideoIdentifierIsAcceptable() throws {
    var sample = sampleResource
    sample["attributes"]["video_identifier"] = JSON(NSNull())
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.videoIdentifier)
  }
  
  func testMissingVideoIdentifierIsAcceptable() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "video_identifier")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    let content = try ContentAdapter.process(resource: resource, relationships: relationships)
    XCTAssertNil(content.videoIdentifier)
  }
}
