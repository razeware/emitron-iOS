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
import CombineExpectations
@testable import Emitron

class SettingsManagerTest: XCTestCase {
  private let userDefaultsSuite = "TestSuite"
  let userModelController = UserMCMock()
  var settingsManager: SettingsManager!

  override func setUp() {
    super.setUp()
    let userDefaults = UserDefaults(suiteName: userDefaultsSuite)!
    settingsManager = SettingsManager(
      userDefaults: userDefaults,
      userModelController: userModelController
    )
  }

  override func tearDown() {
    super.tearDown()
    UserDefaults().removePersistentDomain(forName: userDefaultsSuite)
  }
  
  func testResetAllRemovesValuesInUserDefaults() {
    var persistentDomain: [String: Any]? {
      UserDefaults().persistentDomain(forName: userDefaultsSuite)
    }

    XCTAssertNil(persistentDomain)
    
    settingsManager.playbackToken = "HELLO"
    settingsManager.playbackSpeed = .double
    settingsManager.wifiOnlyDownloads = true
    settingsManager.downloadQuality = .sdVideoFile
    
    XCTAssertNotNil(persistentDomain)
    
    settingsManager.resetAll()
    
    XCTAssertNil(persistentDomain)
  }
  
  func testFiltersPersistedSuccessfully() {
    settingsManager.filters = [.testFilter]
    
    XCTAssertEqual([.testFilter], settingsManager.filters)
  }
  
  func testFiltersDefaultIsEmptyArray() {
    XCTAssertEqual([], settingsManager.filters)
  }
  
  func testSortFilterPersistedSuccessfully() {
    settingsManager.sortFilter = .popularity
    
    XCTAssertEqual(.popularity, settingsManager.sortFilter)
  }
  
  func testSortFilterDefaultIsNewest() {
    XCTAssertEqual(.newest, settingsManager.sortFilter)
  }
  
  func testPlaybackTokenSuccessfullyPersisted() {
    settingsManager.playbackToken = "HELLO"
    
    XCTAssertEqual("HELLO", settingsManager.playbackToken)
  }
  
  func testPlaybackTokenDefaultIsNil() {
    XCTAssertNil(settingsManager.playbackToken)
  }
  
  func testPlaybackSpeedSuccessfullyPersisted() {
    settingsManager.playbackSpeed = .double
    
    XCTAssertEqual(.double, settingsManager.playbackSpeed)
  }
  
  func testPlaybackSpeedDefaultIsStandard() {
    XCTAssertEqual(.standard, settingsManager.playbackSpeed)
  }
  
  func testPlaybackSpeedPublisherSendsUpdates() throws {
    let recorder = settingsManager.playbackSpeedPublisher.record()
    
    settingsManager.playbackSpeed = .double
    settingsManager.playbackSpeed = .standard
    settingsManager.playbackSpeed = .onePointFive
    
    let stream = try wait(for: recorder.next(3), timeout: 2)
    
    XCTAssertEqual([.double, .standard, .onePointFive], stream)
  }
  
  func testClosedCaptionOnSuccessfullyPersisted() {
    settingsManager.closedCaptionOn = true
    
    XCTAssertTrue(settingsManager.closedCaptionOn)
  }
  
  func testClosedCaptionOnDefaultIsFalse() {
    XCTAssertFalse(settingsManager.closedCaptionOn)
  }
  
  func testClosedCaptionOnPublisherSendsUpdates() throws {
    let recorder = settingsManager.closedCaptionOnPublisher.record()
    
    settingsManager.closedCaptionOn = false
    settingsManager.closedCaptionOn = true
    settingsManager.closedCaptionOn = true
    
    let stream = try wait(for: recorder.next(3), timeout: 2)
    
    XCTAssertEqual([false, true, true], stream)
  }
  
  func testDownloadQualitySuccessfullyPersisted() {
    settingsManager.downloadQuality = .sdVideoFile
    
    XCTAssertEqual(.sdVideoFile, settingsManager.downloadQuality)
  }
  
  func testDownloadQualityDefaultIsHD() {
    XCTAssertEqual(.hdVideoFile, settingsManager.downloadQuality)
  }
  
  func testDownloadQualityPublisherSendsUpdates() throws {
    let recorder = settingsManager.downloadQualityPublisher.record()
    
    settingsManager.downloadQuality = .hdVideoFile
    settingsManager.downloadQuality = .sdVideoFile
    settingsManager.downloadQuality = .sdVideoFile
    
    let stream = try wait(for: recorder.next(3), timeout: 2)
    
    XCTAssertEqual([.hdVideoFile, .sdVideoFile, .sdVideoFile], stream)
  }
  
  func testWifiOnlyDownloadsSuccessfullyPersisted() {
    settingsManager.wifiOnlyDownloads = true
    
    XCTAssertTrue(settingsManager.wifiOnlyDownloads)
  }
  
  func testWifiOnlyDownloadsDefaultIsFalse() {
    XCTAssertFalse(settingsManager.wifiOnlyDownloads)
  }
  
  func testWifiOnlyDownloadsPublisherSendsUpdates() throws {
    let recorder = settingsManager.wifiOnlyDownloadsPublisher.record()
    
    settingsManager.wifiOnlyDownloads = true
    settingsManager.wifiOnlyDownloads = false
    settingsManager.wifiOnlyDownloads = false
    
    let stream = try wait(for: recorder.next(3), timeout: 2)
    
    XCTAssertEqual([true, false, false], stream)
  }
}
