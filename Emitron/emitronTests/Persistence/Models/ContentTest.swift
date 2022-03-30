// Copyright (c) 2022 Razeware LLC
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
import GRDB
@testable import Emitron

class ContentTest: XCTestCase, DatabaseTestCase {
  private(set) var database: TestDatabase!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try EmitronDatabase.test
  }
  
  func testCanCreateContentWithoutADownload() throws {
    // Start with no content
    XCTAssert(try allContents.isEmpty)
    
    // Create contents
    let content = PersistenceMocks.content
    try database.write(content.save)
    
    // Should have one item of content
    XCTAssertEqual(1, try allContents.count)
    // It should be the right one
    XCTAssertEqual(content.uri, try allContents.first!.uri)
    XCTAssertEqual(content, try allContents.first)
  }
  
  func testCanAssignContentToADownload() throws {
    let content = PersistenceMocks.content
    try database.write { db in
      try content.save(db)
    }
      
    var download = PersistenceMocks.download(for: content)
    try database.write { db in
      try download.save(db)
    }
      
    // Should have one item of content
    XCTAssertEqual(1, try allContents.count)
    // It should be the right one
    XCTAssertEqual(content, try allContents.first)
    // There should be a single download
    XCTAssertEqual(1, try allDownloads.count)
    // It too should be the right one
    XCTAssertEqual(download, try allDownloads.first)
  }
  
  func testDeletingTheContentDeletesTheDownload() throws {
    let content = PersistenceMocks.content
    try database.write(content.save)
      
    var download = PersistenceMocks.download(for: content)
    try database.write { db in
      try download.save(db)
    }
      
    // Should have one item of content
    XCTAssertEqual(1, try allContents.count)
    // It should be the right one
    XCTAssertEqual(content, try allContents.first)
    // There should be a single download
    XCTAssertEqual(1, try allDownloads.count)
    // It too should be the right one
    XCTAssertEqual(download, try allDownloads.first)
    
    _ = try database.write { db in
      try content.delete(db)
    }
    
    // Check it was deleted
    XCTAssertEqual(0, try allContents.count)
    // And that the download was deleted too
    XCTAssertEqual(0, try allDownloads.count)
  }
}
