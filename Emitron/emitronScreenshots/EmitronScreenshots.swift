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

class EmitronScreenshots: XCTestCase {
  func testTakeSnapshots() {
    let app = XCUIApplication()
    setupSnapshot(app)
    app.launch()

    let contentList = app.descendants(matching: .any)
                         .matching(identifier: "contentListView")
                         .element
    _ = contentList.waitForExistence(timeout: 20)
    snapshot("01Library")
    
    // Reset filters
    app.buttons.matching(identifier: "Filter Library").element.tap()
    app.buttons.matching(identifier: "Clear All").element.tap()
    
    // Now set some and screenshot
    app.buttons.matching(identifier: "Filter Library").element.tap()
    app.buttons.matching(identifier: "Platforms").element.tap()
    app.descendants(matching: .any).matching(identifier: "Toggle iOS & Swift").element.tap()
    app.buttons.matching(identifier: "Content Type").element.tap()
    app.descendants(matching: .any).matching(identifier: "Toggle Video Course").element.tap()
    snapshot("02Filters")
    
    app.buttons.matching(identifier: "Apply").element.tap()
    snapshot("03FilteredLibrary")
    
    app.tables.cells.element(boundBy: 1).tap()
    _ = app.descendants(matching: .any).matching(identifier: "childContentList").element.waitForExistence(timeout: 10)
    app.descendants(matching: .any).matching(identifier: "Bookmark course").element.tap()
    snapshot("04Course")
    
    app.descendants(matching: .any).matching(identifier: "Download course").element.tap()
    app.tabBars.buttons.matching(identifier: "Downloads").element.tap()
    snapshot("05Downloads")

    app.tabBars.buttons.matching(identifier: "My Tutorials").element.tap()
    app.buttons.matching(identifier: "Bookmarks").element.tap()
    snapshot("06Bookmarks")
  }
}
