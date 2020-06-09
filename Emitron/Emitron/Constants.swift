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

import typealias Foundation.TimeInterval
import CoreGraphics.CGBase

enum Constants {
  static let filters = "Filters"
  static let clearAll = "Clear All"
  static let search = "Search…"
  static let loading = "Loading…"
  static let library = "Library"
  static let myTutorials = "My Tutorials"
  static let downloads = "Downloads"
  static let newest =  "Newest"
  static let popularity = "Popularity"
  static let tutorials = "Tutorials"
  static let settings = "Settings"
  
  // Onboarding
  static let login = "Login"
  
  // Other
  static let today = "Today"
  static let by = "By"
  static let yes = "Yes"
  static let no = "No" // swiftlint:disable:this identifier_name
  
  // Video playback
  static let videoPlaybackProgressTrackingInterval: Int = 5
  static let videoPlaybackOfflinePermissionsCheckPeriod: TimeInterval = 7 * 24 * 60 * 60
  
  // Message Banner
  static let autoDismissTime: TimeInterval = 3
  
  // Appearance
  static let blurRadius: CGFloat = 5
  
  // Messaging
  static let bookmarkCreated = "Content bookmarked successfully."
  static let bookmarkDeleted = "Bookmark removed successfully."
  static let bookmarkCreatedError = "There was a problem creating the bookmark"
  static let bookmarkDeletedError = "There was a problem deleting the bookmark"
  
  static let progressRemoved = "Progress removed successfully."
  static let progressMarkedAsComplete = "Content marked as complete."
  static let progressRemovedError = "There was a problem removing progress."
  static let progressMarkedAsCompleteError = "There was a problem marking content as complete."
  
  static let downloadRequestedSuccessfully = "Download enqueued."
  static let downloadRequestedButQueueInactive = "Download will begin when WiFi available."
  static let downloadNotPermitted = "Download not permitted."
  static let downloadContentNotFound = "Invalid download request."
  static let downloadRequestProblem = "Problem requesting download."
  static let downloadCancelled = "Download cancelled."
  static let downloadDeleted = "Download deleted."
  static let downloadReset = "Download reset."
  static let downloadUnspecifiedProblem = "Problem with download action."
  static let downloadUnableToCancel = "Unable to cancel download."
  static let downloadUnableToDelete = "Unable to delete download."
  
  static let simultaneousStreamsError = "You can only stream on one device at a time."
  
  static let downloadedContentNotFound = "Unable to find download."
  
  static let videoPlaybackCannotStreamWhenOffline = "Cannot stream video when offline."
  static let videoPlaybackInvalidPermissions = "You don't have the required permissions to view this video."
  static let videoPlaybackExpiredPermissions = "Download expired. Please reconnect to the internet to reverify."
  
  static let appIconUpdatedSuccessfully = "You app icon has been updated!"
  static let appIconUpdateProblem = "There was a problem updating the app icon."
  
  // Settings screens
  static let settingsPlaybackSpeedLabel = "Video Playback Speed"
  static let settingsWifiOnlyDownloadsLabel = "Downloads (WiFi only)"
  static let settingsDownloadQualityLabel = "Downloads Quality"
  static let settingsClosedCaptionOnLabel = "Subtitles"
  
  // Detail View
  static let detailContentLockedCosPro = "Upgrade your account to watch this and other Pro courses"
  
  // Pull-to-refresh
  static let pullToRefreshPullMessage = "Pull to refresh"
  static let pullToRefreshLoadingMessage = "Loading…"
}
