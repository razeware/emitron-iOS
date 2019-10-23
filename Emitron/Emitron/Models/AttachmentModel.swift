/// Copyright (c) 2019 Razeware LLC
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

import Foundation

enum AttachmentKind: String {
  case none
  case stream
  case sdVideoFile = "sd_video_file"
  case hdVideoFile = "hd_video_file"
  
  static func getDetail(value: String) -> String {
    if value == AttachmentKind.sdVideoFile.rawValue {
      return "SD"
    } else if value == AttachmentKind.hdVideoFile.rawValue {
      return "HD"
    } else {
      return value
    }
  }
  
  static func getValue(detail: String) -> String {
    if detail == "SD" {
      return AttachmentKind.sdVideoFile.rawValue
    } else if detail == "HD" {
      return AttachmentKind.hdVideoFile.rawValue
    } else {
      return detail
    }
  }
}

class AttachmentModel {

  // MARK: - Properties
  private(set) var id: Int = 0
  private(set) var url: URL?
  private(set) var kind: AttachmentKind = .none

  // MARK: - Initializets
  init?(_ jsonResource: JSONAPIResource,
        metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.url = URL(string: (jsonResource["url"] as? String) ?? "")

    if let attachmentKind = AttachmentKind(rawValue: jsonResource["kind"] as? String ?? AttachmentKind.none.rawValue) {
      self.kind = attachmentKind
    }
  }
}
