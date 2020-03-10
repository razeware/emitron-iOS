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
@testable import Emitron

class UserTest: XCTestCase {

  override func setUp() {
    super.setUp()
  }
  
  let userDictionary = [
    "external_id": "sample_external_id",
    "email": "email@example.com",
    "username": "sample_username",
    "avatar_url": "http://example.com/avatar.jpg",
    "name": "Sample Name",
    "token": "Samaple.Token"
  ]
  
  func testUserCorrectlyPopulatesWithDictionary() {
    guard let user = User(dictionary: userDictionary) else {
      XCTFail("User should be correctly populated")
      return
    }
    
    XCTAssertEqual(userDictionary["external_id"], user.externalId)
    XCTAssertEqual(userDictionary["email"], user.email)
    XCTAssertEqual(userDictionary["username"], user.username)
    XCTAssertEqual(userDictionary["avatar_url"], user.avatarUrl.absoluteString)
    XCTAssertEqual(userDictionary["name"], user.name)
    XCTAssertEqual(userDictionary["token"], user.token)
  }
  
  func testUserDictionaryHasRequiredFields() {
    var invalidDictionary = userDictionary
    invalidDictionary.removeValue(forKey: "external_id")
    let user = User(dictionary: invalidDictionary)
    
    XCTAssertNil(user)
  }
  
  func testAdditionalEntriesInTheDictionaryAreIgnored() {
    var overSpecifiedDictionary = userDictionary
    overSpecifiedDictionary["extra_field"] = "some-guff"
    let user = User(dictionary: overSpecifiedDictionary)
    
    XCTAssertNotNil(user)
  }
  
  func testAvatarURLMustBeAURL() {
    var invalidDictionary = userDictionary
    invalidDictionary["avatar_url"] = "not a url"
    let user = User(dictionary: invalidDictionary)
    
    XCTAssertNil(user)
  }
  
  func testNoPermissionsWorksAsExpected() {
    let user = User.noPermissions
    
    XCTAssert(!user.canDownload)
    XCTAssert(!user.canStream)
    XCTAssert(!user.canStreamPro)
  }
  
  func testWithDownloadsMockWorksAsExpected() {
    let user = User.withDownloads
    
    XCTAssert(user.canDownload)
    XCTAssert(!user.canStream)
    XCTAssert(!user.canStreamPro)
  }
}
