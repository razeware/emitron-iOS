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

class CategoryAdapterTest: XCTestCase {
  let sampleResource: JSON = [
    "id": "1234",
    "type": "categories",
    "attributes": [
      "name": "Algorithms & Data Structures",
      "uri": "rw://carolus/categories/1234",
      "ordinal": 5
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
    
    let category = try CategoryAdapter.process(resource: resource)
    
    XCTAssertEqual(1234, category.id)
    XCTAssertEqual("Algorithms & Data Structures", category.name)
    XCTAssertEqual("rw://carolus/categories/1234", category.uri)
    XCTAssertEqual(5, category.ordinal)
  }
  
  func testInvalidTypeThrows() throws {
    var sample = sampleResource
    sample["type"] = "invalid"
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try CategoryAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidResourceTypeForAdapter, error as! EntityAdapterError)
    }
  }
  
  func testMissingNameThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "name")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try CategoryAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingUriThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "uri")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try CategoryAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
  
  func testMissingOrdinalThrows() throws {
    var sample = sampleResource
    sample["attributes"].dictionaryObject?.removeValue(forKey: "ordinal")
    
    let resource = try makeJsonAPIResource(for: sample)
    
    XCTAssertThrowsError(try CategoryAdapter.process(resource: resource)) { error in
      XCTAssertEqual(EntityAdapterError.invalidOrMissingAttributes, error as! EntityAdapterError)
    }
  }
}
