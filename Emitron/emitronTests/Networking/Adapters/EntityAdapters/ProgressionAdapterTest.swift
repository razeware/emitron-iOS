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

class ProgressionAdapterTest: XCTestCase {
  let sampleResource: JSON = [
    "id": "1234",
    "type": "progressions",
    "attributes": [
      "target": 1000,
      "progress": 600,
      "finished": false,
      "percent_complete": 0.6,
      "created_at": "2020-01-01T12:00:00.000Z",
      "updated_at": "2020-01-02T14:00:00.000Z"
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
      "self": "https://example.com/progressions/1234"
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
    
    let progression = try ProgressionAdapter.process(resource: resource)
    
    XCTAssertEqual(1234, progression.id)
    XCTAssertEqual(1000, progression.target)
    XCTAssertEqual(600, progression.progress)
    var cmpts = DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2020, month: 1, day: 1, hour: 12, minute: 0, second: 0)
    XCTAssertEqual(Calendar.current.date(from: cmpts), progression.createdAt)
    cmpts.day = 2
    cmpts.hour = 14
    XCTAssertEqual(Calendar.current.date(from: cmpts), progression.updatedAt)
    XCTAssertEqual(4321, progression.contentId)
  }
  
  func testInvalidTypeThrows() throws {
    var sample = sampleResource
    sample["type"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidResourceTypeForAdapter, error as! EntityAdapterError)
    }
  }
  
  func testInvalidTargetThrows() throws {
    var sample = sampleResource
    sample["attributes"]["target"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidProgressThrows() throws {
    var sample = sampleResource
    sample["attributes"]["progress"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidCreatedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["created_at"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidUpdatedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["updated_at"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingFinishedAndPercentCompleteHaveNoEffect() throws {
    var sample = sampleResource
    sample.dictionaryObject?.removeValue(forKey: "finished")
    sample.dictionaryObject?.removeValue(forKey: "percent_complete")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertNoThrow(try ProgressionAdapter.process(resource: resource))
  }
  
  func testMissingContentRelationshipThrows() throws {
    var sample = sampleResource
    sample["relationships"] = []
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try ProgressionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingRelationships, error as! EntityAdapterError)
    }
  }
}
