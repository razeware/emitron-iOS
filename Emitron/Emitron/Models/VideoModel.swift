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
import SwiftyJSON

struct VideoFile {
  let kind: VideoKind
  let url: URL
}

enum VideoKind: String {
  case none
  case stream
  case sdVideo
  case hdVideo
}

class VideoModel {

  // MARK: - Properties
  private(set) var id: Int = 0
  private(set) var name: String = ""
  private(set) var description: String = ""
  private(set) var free: Bool = false

  //TODO There's something funky going on with Date's in Xcode 11
  private(set) var releasedAt: Date
  private(set) var createdAt: Date
  private(set) var updatedAt: Date
  private(set) var streamFile: VideoFile?
  private(set) var sdVideoFile: VideoFile?
  private(set) var hdVideoFile: VideoFile?

  // MARK: - Initializers
  init(_ jsonResource: JSONAPIResource,
       metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String ?? ""
    self.description = jsonResource["description"] as? String ?? ""
    self.free = jsonResource["free"] as? Bool ?? false

    if let releasedAt = jsonResource["released_at"] as? String {
      self.releasedAt = DateFormatter.apiDateFormatter.date(from: releasedAt) ?? Date()
    } else {
      self.releasedAt = Date()
    }

    if let createdAtStr = jsonResource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }

    if let updatedAtStr = jsonResource["updated_at"] as? String {
      self.updatedAt = DateFormatter.apiDateFormatter.date(from: updatedAtStr) ?? Date()
    } else {
      self.updatedAt = Date()
    }
  }
}

extension VideoModel {
  static var test: VideoModel {
    do {
      let fileURL = Bundle.main.url(forResource: "VideoModelTest", withExtension: "json")
      let data = try Data(contentsOf: fileURL!)
      let json = try JSON(data: data)
    
      let document = JSONAPIDocument(json)
      let resource = JSONAPIResource(json, parent: document)
      return VideoModel(resource, metadata: nil)
    } catch {
      let resource = JSONAPIResource()
      return VideoModel(resource, metadata: nil)
    }
  }
}