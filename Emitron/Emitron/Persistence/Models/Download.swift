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
import GRDB

struct Download: Codable, TableRecord {
  enum State: Int, Codable {
    case pending, urlRequested, readyForDownload, enqueued, inProgress, paused, cancelled, failed, complete, error
  }
  
  var id: UUID
  var requestedAt: Date
  var lastValidatedAt: Date?
  var fileName: String?
  var localUrl: URL?
  var remoteUrl: URL?
  var progress: Double = 0
  var state: State
  var contentId: Int
}

extension Download: FetchableRecord, MutablePersistableRecord {
  enum Columns {
    static let id = Column(CodingKeys.id)
    static let requestedAt = Column(CodingKeys.requestedAt)
    static let lastValidatedAt = Column(CodingKeys.lastValidatedAt)
    static let fileName = Column(CodingKeys.fileName)
    static let localUrl = Column(CodingKeys.localUrl)
    static let remoteUrl = Column(CodingKeys.remoteUrl)
    static let progress = Column(CodingKeys.progress)
    static let state = Column(CodingKeys.state)
    static let contentId = Column(CodingKeys.contentId)
  }
}

extension Download {
  static let content = belongsTo(Content.self)
  var content: QueryInterfaceRequest<Content> {
    request(for: Download.content)
  }
}

extension DerivableRequest where RowDecoder == Download {
  func filter(state: Download.State) -> Self {
    return filter(Download.Columns.state == state.rawValue)
  }
  
  func orderByRequestedAt() -> Self {
    let requestedAt = Download.Columns.requestedAt
    return order(requestedAt.asc)
  }
}

extension Download: DownloadProcessorModel { }

extension Download: Equatable {
  // We override this function because SQLite doesn't store dates to the same accuracy as Date
  static func == (lhs: Download, rhs: Download) -> Bool {
    lhs.id == rhs.id &&
      lhs.fileName == rhs.fileName &&
      lhs.localUrl == rhs.localUrl &&
      lhs.remoteUrl == rhs.remoteUrl &&
      lhs.progress == rhs.progress &&
      lhs.state == rhs.state &&
      lhs.contentId == rhs.contentId &&
      lhs.requestedAt.equalEnough(to: rhs.requestedAt) &&
      ((lhs.lastValidatedAt == nil && rhs.lastValidatedAt == nil) || lhs.lastValidatedAt!.equalEnough(to: rhs.lastValidatedAt!))
  }
}

extension Download {
  static func create(for content: Content) -> Download {
    return Download(
      id: UUID(),
      requestedAt: Date(),
      lastValidatedAt: nil,
      fileName: nil,
      localUrl: nil,
      remoteUrl: nil,
      progress: 0,
      state: .pending,
      contentId: content.id)
  }
}
