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

import Combine

enum SettingsOption: Int, Identifiable, CaseIterable {
  case playbackSpeed
  case wifiOnlyDownloads
  case downloadQuality
  case closedCaptionOn
  
  var id: Int {
    rawValue
  }
  
  var title: String {
    switch self {
    case .playbackSpeed:
      return Constants.settingsPlaybackSpeedLabel
    case .wifiOnlyDownloads:
      return Constants.settingsWifiOnlyDownloadsLabel
    case .downloadQuality:
      return Constants.settingsDownloadQualityLabel
    case .closedCaptionOn:
      return Constants.settingsClosedCaptionOnLabel
    }
  }
  
  var key: SettingsKey {
    switch self {
    case .playbackSpeed:
      return .playbackSpeed
    case .wifiOnlyDownloads:
      return .wifiOnlyDownloads
    case .downloadQuality:
      return .downloadQuality
    case .closedCaptionOn:
      return .closedCaptionOn
    }
  }
  
  var detail: [String] {
    switch self {
    case .playbackSpeed:
      return PlaybackSpeed.allCases.map(\.display)
    case .wifiOnlyDownloads:
      return ["Yes", "No"]
    case .downloadQuality:
      return Attachment.Kind.downloads.map(\.display)
    case .closedCaptionOn:
      return ["Yes", "No"]
    }
  }
  
  var isToggle: Bool {
    switch self {
    case .wifiOnlyDownloads, .closedCaptionOn:
      return true
    default:
      return false
    }
  }
}
