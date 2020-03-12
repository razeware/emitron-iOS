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

class BookmarkAdapterTest: XCTestCase {
  let sampleResource: JSON = [
    "id": "1234",
    "type": "bookmarks",
    "attributes": [
      "created_at": "2020-01-01T12:00:00.000Z"
    ],
    "relationships": [
      "content": [
        "data": [
          "id": 4321,
          "type": "contents"
        ],
        "links": [
          "self": "https://example.com/contents/4321"
        ]
      ]
    ],
    "links": [
      "self": "https://example.com/bookmarks/1234"
    ]
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
    
    let bookmark = try BookmarkAdapter.process(resource: resource)
    
    XCTAssertEqual(1234, bookmark.id)
    let cmpts = DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2020, month: 1, day: 1, hour: 12, minute: 0, second: 0)
    XCTAssertEqual(Calendar.current.date(from: cmpts), bookmark.createdAt)
    XCTAssertEqual(4321, bookmark.contentId)
  }
  
  func testInvalidTypeThrows() throws {
    var sample = sampleResource
    sample["type"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try BookmarkAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidResourceTypeForAdapter, error as! EntityAdapterError)
    }
  }
  
  func testInvalidCreatedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["created_at"] = "this is not a valid time"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try BookmarkAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingContentRelationshipThrows() throws {
    var sample = sampleResource
    let contentRelationship = sample["relationships"]["contents"]
    sample["relationships"] = ["not_contents": contentRelationship]
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try BookmarkAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingRelationships, error as! EntityAdapterError)
    }
  }
}
