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

import struct Foundation.Date

struct Progression: Codable {
  var id: Int
  var target: Int
  var progress: Int
  var createdAt: Date
  var updatedAt: Date
  var contentId: Int
}

extension Progression: Equatable {
  static func == (lhs: Progression, rhs: Progression) -> Bool {
    lhs.id == rhs.id &&
      lhs.target == rhs.target &&
      lhs.progress == rhs.progress &&
      lhs.createdAt.equalEnough(to: rhs.createdAt) &&
      lhs.updatedAt.equalEnough(to: rhs.updatedAt) &&
      lhs.contentId == rhs.contentId
  }
}

extension Progression {
  var finished: Bool {
    // This is a really nasty hack. And I take full responsbility for it. But
    // I'm also incredibly lazy. Basically, collections need to be fully complete
    // before being marked as complete. Whereas videos should only be 90% complete.
    // Since we don't know whether this is a video or a collection, we're gonna
    // make the assumption that collections have fewer than 60 items, and videos
    // are longer than a minute. We should probably fix this another day. I am
    // reasonably confident that we never will.
    if target <= 60 {
      return target == progress
    } else {
      return progressProportion > 0.9
    }
  }
  
  var progressProportion: Double {
    Double(progress) / Double(target)
  }
}

extension Progression {
  static func completed(for content: Content) -> Progression {
    withProgress(for: content, progress: content.duration)
  }
  
  static func withProgress(for content: Content, progress: Int) -> Progression {
    Progression(
      id: -1,
      target: content.duration,
      progress: progress,
      createdAt: Date(),
      updatedAt: Date(),
      contentId: content.id
    )
  }
}
