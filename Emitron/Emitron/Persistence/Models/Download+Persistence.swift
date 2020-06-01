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

import GRDB

extension Download: TableRecord, FetchableRecord, MutablePersistableRecord {
  enum Columns {
    static let id = Column("id")
    static let requestedAt = Column("requestedAt")
    static let lastValidatedAt = Column("lastValidatedAt")
    static let fileName = Column("fileName")
    static let remoteUrl = Column("remoteUrl")
    static let progress = Column("progress")
    static let state = Column("state")
    static let contentId = Column("contentId")
    static let ordinal = Column("ordinal")
  }
}

extension Download {
  static let content = belongsTo(Content.self)
  static let group = hasOne(Group.self, through: content, using: Content.group)
  static let parentContent = hasOne(Content.self, through: group, using: Group.content)
  static let parentDownload = hasOne(Download.self, through: parentContent, using: Content.download)
  
  var content: QueryInterfaceRequest<Content> {
    request(for: Download.content)
  }
  
  var parentContent: QueryInterfaceRequest<Content> {
    request(for: Download.parentContent)
  }
  
  var parentDownload: QueryInterfaceRequest<Download> {
    request(for: Download.parentDownload)
  }
}

extension DerivableRequest where RowDecoder == Download {
  func filter(state: Download.State) -> Self {
    filter(Download.Columns.state == state.rawValue)
  }
  
  func orderByRequestedAtAndOrdinal() -> Self {
    let requestedAt = Download.Columns.requestedAt
    let ordinal = Download.Columns.ordinal
    return order(requestedAt.asc, ordinal.asc)
  }
}
