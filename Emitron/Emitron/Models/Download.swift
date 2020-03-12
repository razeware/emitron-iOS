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

struct Download: Codable {
  enum State: Int, Codable {
    case pending // Collection— Just created
    case urlRequested
    case readyForDownload
    case enqueued
    case inProgress // Collection– Not all of the requested children are downloaded
    case paused // Collection— All requested children are downloaded, but not all children have been requested
    case cancelled
    case failed
    case complete // Collection— All children have been requested and downloaded
    case error
  }
  
  var id: UUID
  var requestedAt: Date
  var lastValidatedAt: Date?
  var fileName: String?
  var remoteUrl: URL?
  var progress: Double = 0
  var state: State
  var contentId: Int
  var ordinal: Int = 0 // We copy this from the Content, and it is used to sort the queue
  
  var localUrl: URL? {
    guard let fileName = fileName,
      let downloadDirectory = Download.downloadDirectory else {
        return nil
    }
    
    return downloadDirectory.appendingPathComponent(fileName)
  }
  
  static var downloadDirectory: URL? {
    let fileManager = FileManager.default
    let documentsDirectories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    guard let documentsDirectory = documentsDirectories.first else {
      return nil
    }
    
    return documentsDirectory.appendingPathComponent("downloads", isDirectory: true)
  }
}

extension Download: DownloadProcessorModel { }

extension Download: Equatable {
  // We override this function because SQLite doesn't store dates to the same accuracy as Date
  static func == (lhs: Download, rhs: Download) -> Bool {
    lhs.id == rhs.id &&
      lhs.fileName == rhs.fileName &&
      lhs.remoteUrl == rhs.remoteUrl &&
      lhs.progress == rhs.progress &&
      lhs.state == rhs.state &&
      lhs.contentId == rhs.contentId &&
      lhs.ordinal == rhs.ordinal &&
      lhs.requestedAt.equalEnough(to: rhs.requestedAt) &&
      ((lhs.lastValidatedAt == nil && rhs.lastValidatedAt == nil) || lhs.lastValidatedAt!.equalEnough(to: rhs.lastValidatedAt!))
  }
}

extension Download {
  static func create(for content: Content) -> Download {
    Download(
      id: UUID(),
      requestedAt: Date(),
      lastValidatedAt: nil,
      fileName: nil,
      remoteUrl: nil,
      progress: 0,
      state: .pending,
      contentId: content.id,
      ordinal: content.ordinal ?? 0)
  }
}

extension Download {
  var isDownloading: Bool {
    [.inProgress, .paused].contains(state) && remoteUrl != nil
  }
  
  var isDownloaded: Bool {
    [.complete].contains(state) && remoteUrl != nil
  }
}

extension Download: Hashable { }
