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

enum ContentViewProgressDisplayable {
  case notStarted
  case inProgress(progress: Double)
  case completed
}

enum DownloadProgressDisplayable {
  case notDownloadable
  case downloadable
  case enqueued
  case inProgress(progress: Double)
  case downloaded
}

extension DownloadProgressDisplayable {
  var imageName: String {
    switch self {
    case .enqueued, .inProgress:
      return DownloadImageName.active
    default:
      return DownloadImageName.inactive
    }
  }
}

protocol ContentListDisplayable {
  var id: Int { get }
  var name: String { get }
  var cardViewSubtitle: String { get }
  var descriptionPlainText: String { get }
  var professional: Bool { get }
  var viewProgress: ContentViewProgressDisplayable { get }
  var downloadProgress: DownloadProgressDisplayable { get }
  var releasedAt: Date { get }
  var duration: Int { get }
  var releasedAtDateTimeString: String { get }
  var bookmarked: Bool { get }
  var parentName: String? { get }
  var contentType: ContentType { get }
  var cardArtworkUrl: URL? { get }
  var ordinal: Int? { get }
  var technologyTripleString: String { get }
  var contentSummaryMetadataString: String { get }
  var contributorString: String { get }
  
  var groupId: Int? { get }
  var videoIdentifier: Int? { get }
}

protocol ContentDetailDisplayable: ContentListDisplayable {
  var descriptionHtml: String { get }
  var childContents: [Content] { get }
  var groups: [Group] { get }
}


extension ContentListDisplayable {
  var releasedAtDateTimeString: String {
    var start = releasedAt.cardString
    if Calendar.current.isDate(Date(), inSameDayAs: releasedAt) {
      start = Constants.today
    }
    
    return "\(start) • \(contentType.displayString) (\(duration.timeFromSeconds))"
  }
}
