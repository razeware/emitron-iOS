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

enum ContentScreen {
  case library
  case downloads(permitted: Bool)
  case inProgress
  case completed
  case bookmarked

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
    case .library:
      return "We couldn't find anything"
    case .downloads(permitted: true):
      return "You haven't downloaded any tutorials yet"
    case .downloads(permitted: false):
      return "Upgrade your account to download videos"
    case .bookmarked:
      return "You haven't bookmarked any tutorials yet"
    case .inProgress:
      return "You don't have any tutorials in progress yet"
    case .completed:
      return "You haven't completed any tutorials yet"
    }
  }

  var detailMesage: String {
    switch self {
    case .library:
      return "Try removing some filters."
    case .bookmarked:
      return "Tap the bookmark icon to bookmark a video course or screencast."
    case .inProgress:
      return "When you start a video course you can quickly resume it from here."
    case .completed:
      return "Watch all the episodes of a video course or screencast to complete it."
    case .downloads(permitted: true):
      return "Tap the download icon to download a video course or episode to watch offline."
    case .downloads(permitted: false):
      return "Members on the Professional plan are able to download videos and watch them offline."
    }
  }
  
  var showExploreButton: Bool {
    switch self {
    case .downloads(permitted: true), .inProgress, .completed, .bookmarked:
      return true
    case .downloads(permitted: false), .library:
      return false
    }
  }

  var emptyImageName: String {
    switch self {
    case .downloads(permitted: true):
      return "artworkEmptySuitcase"
    case .downloads(permitted: false):
      return "artworkDownloadSwitch"
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
