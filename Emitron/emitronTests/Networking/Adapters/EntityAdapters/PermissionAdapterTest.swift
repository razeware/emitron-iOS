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

class PermissionAdapterTest: XCTestCase {
  let sampleResource: JSON = [
    "id": "1234",
    "type": "permissions",
    "attributes": [
      "name": "Downloadable Videos",
      "tag": "download-videos",
      "created_at": "2020-01-01T12:00:00.000Z",
      "updated_at": "2020-01-02T14:00:00.000Z"
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
    
    guard let permission = try PermissionAdapter.process(resource: resource) else { return XCTFail("Expected non-nil permission") }
    
    XCTAssertEqual(1234, permission.id)
    XCTAssertEqual("Downloadable Videos", permission.name)
    var cmpts = DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: 2020, month: 1, day: 1, hour: 12, minute: 0, second: 0)
    XCTAssertEqual(Calendar.current.date(from: cmpts), permission.createdAt)
    cmpts.day = 2
    cmpts.hour = 14
    XCTAssertEqual(Calendar.current.date(from: cmpts), permission.updatedAt)
    XCTAssertEqual(.download, permission.tag)
  }
  
  func testInvalidTypeThrows() throws {
    var sample = sampleResource
    sample["type"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try PermissionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidResourceTypeForAdapter, error as! EntityAdapterError)
    }
  }
  
  func testMissingNameThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "name")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try PermissionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidTagReturnsNil() throws {
    var sample = sampleResource
    sample["attributes"]["tag"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertNil(try PermissionAdapter.process(resource: resource))
  }
  
  func testInvalidCreatedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["created_at"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try PermissionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testInvalidUpdatedAtThrows() throws {
    var sample = sampleResource
    sample["attributes"]["updated_at"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try PermissionAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
}
