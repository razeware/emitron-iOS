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
@testable import Emitron

class FilterGroupTest: XCTestCase {

  func testUpdateFilterWithExistingFilter() {
    let difficultyFilters = Param
      .filters(for: [.difficulties([.beginner, .intermediate, .advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }

    var difficulties = FilterGroup(type: .difficulties, filters: difficultyFilters)

    let filter = Param
      .filters(for: [.difficulties([.advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: true) }
      .first!

    difficulties.updateFilters(from: [filter])
    XCTAssert(difficulties.filters[2].isOn)
  }

  func testUpdateFilterWithMissingFilter() {
    let difficultyFilters = Param
      .filters(for: [.difficulties([.beginner, .intermediate])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }

    var difficulties = FilterGroup(type: .difficulties, filters: difficultyFilters)

    let filter = Param
      .filters(for: [.difficulties([.advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }
      .first!

    difficulties.updateFilters(from: [filter])
    XCTAssertEqual(difficulties.filters.count, 2)
  }

  func testUpdateFilterWithDifferentFilter() {
    let difficultyFilters = Param
      .filters(for: [.difficulties([.beginner])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }

    var difficulties = FilterGroup(type: .difficulties, filters: difficultyFilters)

    let filter = Param
      .filters(for: [.difficulties([.advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: true) }
      .first!

    difficulties.updateFilters(from: [filter])
    XCTAssertFalse(difficulties.filters[0].isOn)
  }
}
