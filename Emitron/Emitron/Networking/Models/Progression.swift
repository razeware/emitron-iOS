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

class Progression {

  private(set) var id: Int = 0
  private(set) var target: Int = 0
  private(set) var progress: Int = 0
  private(set) var finished: Bool = false
  private(set) var percentComplete: Double = 0.0
  // There's something funky going on with Date's in Xcode 11
  private(set) var createdAt: Date
  private(set) var updatedAt: Date

  init(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {

    self.id = jsonResource.id
    self.target = jsonResource["target"] as? Int ?? 0
    self.progress = jsonResource["progress"] as? Int ?? 0
    self.finished = jsonResource["finished"] as? Bool ?? false
    self.percentComplete = jsonResource["percent_complete"] as? Double ?? 0.0

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
