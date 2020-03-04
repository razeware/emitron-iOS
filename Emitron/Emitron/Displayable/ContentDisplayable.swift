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

import Foundation

// MARK: - Shared
// These are used every time we see content.

/// The progress the current user has made through this item of content
enum ContentViewProgressDisplayable {
  case notStarted
  case inProgress(progress: Double)
  case completed
  
  init(progression: Progression?) {
    switch progression {
    case .none:
      self = .notStarted
    case .some(let prog) where prog.finished:
      self = .completed
    case .some(let prog):
      self = .inProgress(progress: prog.progressProportion)
    }
  }
}

/// Whether or not this item of content has been downloaded, or is downloading
enum DownloadProgressDisplayable: CustomStringConvertible {
  case notDownloadable
  case downloadable
  case enqueued
  case inProgress(progress: Double)
  case downloaded
  
  init(download: Download?) {
    guard let download = download else {
      self = .downloadable
      return
    }

    switch download.state {
    case .cancelled, .error, .failed:
      self = .notDownloadable
    case .enqueued, .pending, .urlRequested, .readyForDownload:
      self = .enqueued
    case .inProgress:
      self = .inProgress(progress: download.progress)
    case .complete:
      self = .downloaded
    case .paused:
      self = .downloadable
    }
  }
  
  var description: String {
    switch self {
    case .notDownloadable:
      return "notDownloadable"
    case .downloadable:
      return "downloadable"
    case .enqueued:
      return "enqueued"
    case .inProgress(progress: let progress):
      return "inProgress(\(progress))"
    case .downloaded:
      return "downloaded"
    }
  }
  
  var accessibilityDescription: String {
    switch self {
    case .notDownloadable:
      return "Reset download"
    case .downloadable:
      return "Download"
    case .enqueued, .inProgress:
      return "Cancel download"
    case .downloaded:
      return "Delete download"
    }
  }
}

// MARK: - Content Listing

/// Suitable for content listing view, and the summary section of the content details view
protocol ContentListDisplayable: Ownable {
  var id: Int { get }
  var name: String { get }
  var cardViewSubtitle: String { get }
  var descriptionPlainText: String { get }
  var releasedAt: Date { get }
  var duration: Int { get }
  var releasedAtDateTimeString: String { get }
  var parentName: String? { get }
  var contentType: ContentType { get }
  var cardArtworkUrl: URL? { get }
  var ordinal: Int? { get }
  var technologyTripleString: String { get }
  var contentSummaryMetadataString: String { get }
  var contributorString: String { get }
  // Probably only populated for screencasts
  var videoIdentifier: Int? { get }
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

// MARK: - Child Contents Table
// For display on the content details view page

/// Required to display a line item in the table. These should all be .episode
protocol ChildContentListDisplayable: Ownable {
  var id: Int { get }
  var name: String { get }
  var ordinal: Int? { get }
  var duration: Int { get }
  var groupId: Int? { get }
  var videoIdentifier: Int? { get }
}

/// Group the contents appropriately
protocol GroupDisplayable {
  var id: Int { get }
  var name: String { get }
  var description: String? { get }
  var ordinal: Int { get }
}
