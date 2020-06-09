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

import struct Foundation.URL

struct Attachment: Codable {
  enum Kind: Int, Codable, CaseIterable, SettingsSelectable {
    case stream
    case sdVideoFile
    case hdVideoFile
    
    init?(from string: String) {
      switch string {
      case "stream":
        self = .stream
      case "sd_video_file":
        self = .sdVideoFile
      case "hd_video_file":
        self = .hdVideoFile
      default:
        return nil
      }
    }
    
    static func fromDisplay(_ value: String) -> Kind? {
      allCases.first { $0.display == value }
    }
    
    var display: String {
      switch self {
      case .stream:
        return "stream"
      case .hdVideoFile:
        return "HD"
      case .sdVideoFile:
        return "SD"
      }
    }
    
    var apiValue: String {
      switch self {
      case .stream:
        return "stream"
      case .hdVideoFile:
        return "hd_video_file"
      case .sdVideoFile:
        return "sd_video_file"
      }
    }
    
    static var downloads: [Kind] {
      [.sdVideoFile, .hdVideoFile]
    }
    
    static var selectableCases: [Attachment.Kind] {
      [.sdVideoFile, .hdVideoFile]
    }
  }
  
  var id: Int
  var kind: Kind
  var url: URL
}
