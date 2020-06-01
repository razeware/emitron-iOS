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
import Combine
@testable import Emitron

class PublishedPostFactoTest: XCTestCase {

  class PrePostObservedObject: ObservablePrePostFactoObject {
    // This doesn't get syntesized
    let objectDidChange = ObservableObjectPublisher()
    
    @Published var notifiedBeforeChangeCommitted: Int = 0
    @PublishedPrePostFacto var notifiedAfterChangeCommitted: Int = 0
  }
  
  var observedObject: PrePostObservedObject!
  
  override func setUp() {
    super.setUp()
    observedObject = PrePostObservedObject()
  }
  
  func testNotifiedBeforeChangeWithPublished() throws {
    let recorder = observedObject.objectWillChange.record()
    
    observedObject.notifiedBeforeChangeCommitted = 1
    try wait(for: recorder.next(), timeout: 1)
  }
  
  func testGetNotificationsOfValueChangesFromPublished() throws {
    let recorder = observedObject.$notifiedBeforeChangeCommitted.record()
    
    observedObject.notifiedBeforeChangeCommitted = 1
    observedObject.notifiedAfterChangeCommitted = 2
    observedObject.notifiedBeforeChangeCommitted = 3
    observedObject.notifiedAfterChangeCommitted = 4
    
    let values = try wait(for: recorder.next(3), timeout: 1)
    
    XCTAssertEqual([0, 1, 3], values)
  }
  
  func testNotifiedAfterChangeWithPublishedPostFacto() throws {
    let recorder = observedObject.objectDidChange.record()
    
    observedObject.notifiedAfterChangeCommitted = 1
    try wait(for: recorder.next(), timeout: 1)
  }
  
  func testGetNotificationsOfValueChangesFromPublishedPostFacto() throws {
    let recorder = observedObject.$notifiedAfterChangeCommitted.record()
    
    observedObject.notifiedBeforeChangeCommitted = 1
    observedObject.notifiedAfterChangeCommitted = 2
    observedObject.notifiedBeforeChangeCommitted = 3
    observedObject.notifiedAfterChangeCommitted = 4
    
    let values = try wait(for: recorder.next(3), timeout: 1)
    
    XCTAssertEqual([0, 2, 4], values)
  }
}
