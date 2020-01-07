/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import XCTest
import CombineExpectations
@testable import Emitron

class DataCacheTest: XCTestCase {
  var cache: DataCache!
  
  let screencast = ContentTest.Mocks.screencast
  var sampleContent: Content { screencast.0 }
  var sampleCacheUpdate: DataCacheUpdate { screencast.1 }
  
  override func setUp() {
    cache = DataCache()
  }
  
  func testUpdateUpdatesCacheAppropriately() throws {
    XCTAssertThrowsError(try cache.cachedContentPersistableState(for: sampleContent.id)) { error in
      XCTAssertEqual(.cacheMiss, error as! DataCacheError)
    }
    
    cache.update(from: sampleCacheUpdate)
    
    let persistableState = try cache.cachedContentPersistableState(for: sampleContent.id)
    XCTAssertNotNil(persistableState)
  }
  
  func testContentSummaryStateSendsWhenDataCacheUpdated() throws {
    let publisher = cache.contentSummaryState(for: [sampleContent.id])
    cache.update(from: sampleCacheUpdate)
    
    let recorder = publisher.record()
    
    let summary = try wait(for: recorder.next(), timeout: 1)
    
    XCTAssertEqual(sampleContent, summary?.first?.content)
  }
  
  func testContentSummaryStateWhenCacheMiss() throws {
    let publisher = cache.contentSummaryState(for: [sampleContent.id])
    let recorder = publisher.record()
    
    let completion = try wait(for: recorder.completion, timeout: 1)
    if case .finished = completion {
        XCTFail("Should not have finished")
    }
    if case let .failure(error) = completion {
      if error as? DataCacheError != .some(.cacheMiss) {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }
  
  func testContentDetailStateSendsWhenDataCacheUpdated() throws {
    let publisher = cache.contentDetailState(for: sampleContent.id)
    cache.update(from: sampleCacheUpdate)
    
    let recorder = publisher.record()
    
    let detail = try wait(for: recorder.next(), timeout: 1)
    
    XCTAssertEqual(sampleContent, detail?.content)
  }
  
  func testContentDetailStateWhenCacheMiss() throws {
    let publisher = cache.contentDetailState(for: sampleContent.id)
    let recorder = publisher.record()
    
    let completion = try wait(for: recorder.completion, timeout: 1)
    if case .finished = completion {
        XCTFail("Should not have finished")
    }
    if case let .failure(error) = completion {
      if error as? DataCacheError != .some(.cacheMiss) {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }
  
  func testCachedContentPersistableStateFindsAppropriateResult() {
    XCTAssertThrowsError(try cache.cachedContentPersistableState(for: sampleContent.id)) { error in
      XCTAssertEqual(.cacheMiss, error as! DataCacheError)
    }
    
    cache.update(from: sampleCacheUpdate)
    
    XCTAssertThrowsError(try cache.cachedContentPersistableState(for: 1234)) { error in
      XCTAssertEqual(.cacheMiss, error as! DataCacheError)
    }
  }
  
  func testCachedContentPersistableStateThrowsIfCacheMiss() throws {
    cache.update(from: sampleCacheUpdate)
    
    let persistableState = try cache.cachedContentPersistableState(for: sampleContent.id)
    XCTAssertEqual(sampleContent, persistableState.content)
  }
  
  func testCacheUpdateWorksWithCollection() throws {
    let collection = ContentTest.Mocks.collection
    
    cache.update(from: collection.1)
    
    let persistableState = try cache.cachedContentPersistableState(for: collection.0.id)
    XCTAssertEqual(collection.0, persistableState.content)
    XCTAssert(persistableState.groups.count > 0)
    XCTAssert(persistableState.childContents.count > 0)
    
    let exampleChildId = persistableState.childContents.first!.id
    
    let publisher = cache.contentSummaryState(for: [exampleChildId])
    let recorder = publisher.record()
    
    let summary = try wait(for: recorder.next(), timeout: 1)
    XCTAssertEqual(collection.0, summary?.first?.parentContent)
  }
}
