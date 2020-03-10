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

import XCTest
import GRDB
@testable import Emitron

class DownloadTest: XCTestCase {
  private var database: DatabaseWriter!
  
  override func setUp() {
    super.setUp()
    // swiftlint:disable:next force_try
    database = try! EmitronDatabase.testDatabase()
  }
  
  func getAllContents() -> [Content] {
    // swiftlint:disable:next force_try
    try! database.read { db in
      try Content.fetchAll(db)
    }
  }
  
  func getAllDownloads() -> [Download] {
    // swiftlint:disable:next force_try
    try! database.read { db in
      try Download.fetchAll(db)
    }
  }
  
  func testDeletingDownloadDoesNotDeleteContents() throws {
    let content = PersistenceMocks.content
    try database.write { db in
      try content.save(db)
    }
      
    var download = PersistenceMocks.download(for: content)
    try database.write { db in
      try download.save(db)
    }
      
    // Should have one item of content
    XCTAssertEqual(1, getAllContents().count)
    // It should be the right one
    XCTAssertEqual(content, getAllContents().first!)
    // There should be a single download
    XCTAssertEqual(1, getAllDownloads().count)
    // It too should be the right one
    XCTAssertEqual(download, getAllDownloads().first!)
    
    _ = try database.write { db in
      try download.delete(db)
    }
      
    // Check it was deleted
    XCTAssertEqual(0, getAllDownloads().count)
    // And that the contents was not deleted
    XCTAssertEqual(1, getAllContents().count)
    XCTAssertEqual(content, getAllContents().first!)
  }
}
