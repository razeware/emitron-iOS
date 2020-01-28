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

enum ContentScreen {
  case library, downloads, inProgress, completed, bookmarked

  var isMyTutorials: Bool {
    switch self {
    case .bookmarked, .inProgress, .completed:
      return true
    default:
      return false
    }
  }

  var titleMessage: String {
    switch self {
    // TODO: maybe this should be a func instead & we can pass in the actual search criteria here
    case .library:
      return "We couldn't find anything with that search criteria."
    case .downloads:
      return "You haven't downloaded any tutorials yet."
    case .bookmarked:
      return "You haven't bookmarked any tutorials yet."
    case .inProgress:
      return "You don't have any tutorials in progress yet."
    case .completed:
      return "You haven't completed any tutorials yet."
    }
  }

  var detailMesage: String {
    switch self {
    case .library:
      return "Try removing some filters or checking your WiFi settings."
    case .bookmarked:
      return "Tap the bookmark icon to bookmark a video course or screencast."
    case .inProgress:
      return "When you start a video course you can quickly resume it from here."
    case .completed:
      return "Watch all the episodes of a video course or screencast to complete it."
    case .downloads:
      return "Tap the download icon to download a video course or episode to watch offline."
    }
  }

  var buttonText: String? {
    switch self {
    case .downloads, .inProgress, .completed, .bookmarked:
      return "Explore Tutorials"
    default:
      return "Reload"
    }
  }

  var emptyImageName: String {
    switch self {
    case .downloads:
      return "artworkEmptySuitcase"
    case .bookmarked:
      return "artworkBookmarks"
    case .inProgress:
      return "artworkInProgress"
    case .completed:
      return "artworkCompleted"
    case .library:
      return "emojiCrying"
    }
  }
}
