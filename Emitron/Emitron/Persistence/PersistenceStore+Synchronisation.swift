// Copyright (c) 2020 Razeware LLC
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
import GRDB
import GRDBCombine

// MARK: - Synchronisation Request Creation
extension PersistenceStore {
  @discardableResult
  func createBookmarkSyncRequest(for contentId: Int) throws -> SyncRequest? {
    try db.write { db in
      // Do we already have a bookmark request?
      if let syncRequest = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.bookmark.rawValue)
        .fetchOne(db) {
        try syncRequest.delete(db)
        return nil
      } else {
        // Need to create a new one
        let syncRequest = SyncRequest(
          contentId: contentId,
          category: .bookmark,
          type: .createBookmark,
          date: Date(),
          attributes: []
        )
        try syncRequest.save(db)
        return syncRequest
      }
    }
  }
  
  @discardableResult
  func deleteBookmarkSyncRequest(for contentId: Int, bookmarkId: Int) throws -> SyncRequest? {
    try db.write { db in
      // Do we already have a bookmark request?
      if let syncRequest = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.bookmark.rawValue)
        .fetchOne(db) {
        try syncRequest.delete(db)
        return nil
      } else {
        // Need to create a new one
        let syncRequest = SyncRequest(
          contentId: contentId,
          associatedRecordId: bookmarkId,
          category: .bookmark,
          type: .deleteBookmark,
          date: Date(),
          attributes: []
        )
        try syncRequest.save(db)
        return syncRequest
      }
    }
  }
  
  @discardableResult
  func markContentAsCompleteSyncRequest(for contentId: Int) throws -> SyncRequest {
    try db.write { db in
      // Do we already have a progress request?
      let syncRequest: SyncRequest
      if var request = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.progress.rawValue)
        .fetchOne(db) {
        request.type = .markContentComplete
        request.date = Date()
        syncRequest = request
      } else {
        // Need to create a new one
        syncRequest = SyncRequest(
          contentId: contentId,
          category: .progress,
          type: .markContentComplete,
          date: Date(),
          attributes: []
        )
      }
      try syncRequest.save(db)
      return syncRequest
    }
  }
  
  @discardableResult
  func updateProgressSyncRequest(for contentId: Int, progress: Int) throws -> SyncRequest {
    try db.write { db in
      // Do we already have a progress request?
      let syncRequest: SyncRequest
      if var request = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.progress.rawValue)
        .fetchOne(db) {
        request.type = .updateProgress
        request.date = Date()
        request.attributes = [.progress(progress)]
        syncRequest = request
      } else {
        // Need to create a new one
        syncRequest = SyncRequest(
          contentId: contentId,
          category: .progress,
          type: .updateProgress,
          date: Date(),
          attributes: [.progress(progress)]
        )
      }
      try syncRequest.save(db)
      return syncRequest
    }
  }
  
  @discardableResult
  func removeProgressSyncRequest(for contentId: Int, progressionId: Int) throws -> SyncRequest {
    try db.write { db in
      // Do we already have a progress request?
      let syncRequest: SyncRequest
      if var request = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.progress.rawValue)
        .fetchOne(db) {
        request.type = .deleteProgression
        request.associatedRecordId = progressionId
        request.date = Date()
        syncRequest = request
      } else {
        // Need to create a new one
        syncRequest = SyncRequest(
          contentId: contentId,
          associatedRecordId: progressionId,
          category: .progress,
          type: .deleteProgression,
          date: Date(),
          attributes: []
        )
      }
      try syncRequest.save(db)
      return syncRequest
    }
  }
  
  @discardableResult
  func watchStatsSyncRequest(for contentId: Int, secondsWatched: Int) throws -> SyncRequest {
    try db.write { db in
      // Do we already have a watch stats request?
      let syncRequest: SyncRequest
      if var request = try SyncRequest
        .filter(SyncRequest.Columns.contentId == contentId)
        .filter(SyncRequest.Columns.category == SyncRequest.Category.watchStat.rawValue)
        .filter(SyncRequest.Columns.date == Date.topOfTheHour)
        .fetchOne(db) {
        request.type = .recordWatchStats
        // The seconds watched are cumulative
        if let attribute = request.attributes.first,
          case .time(let previousSecondsWatched) = attribute {
          request.attributes = [.time(previousSecondsWatched + secondsWatched)]
        } else {
          request.attributes = [.time(secondsWatched)]
        }
        syncRequest = request
      } else {
        // Need to create a new one
        syncRequest = SyncRequest(
          contentId: contentId,
          category: .watchStat,
          type: .recordWatchStats,
          date: Date.topOfTheHour,
          attributes: [.time(secondsWatched)]
        )
      }
      try syncRequest.save(db)
      return syncRequest
    }
  }
}

// MARK: - Synchronisation Queue Management
extension PersistenceStore {
  func syncRequestStream(for types: [SyncRequest.Synchronisation]) -> DatabasePublishers.Value<[SyncRequest]> {
    ValueObservation.tracking { db -> [SyncRequest] in
      let typeValues = types.map(\.rawValue)
      let request = SyncRequest
        .filter(typeValues.contains(SyncRequest.Columns.type))
        .order(SyncRequest.Columns.date.asc)
      
      return try SyncRequest.fetchAll(db, request)
    }
    .removeDuplicates()
    .publisher(in: db)
  }
  
  func complete(syncRequests: [SyncRequest]) {
    do {
      try db.write { db in
        syncRequests.forEach {
          do {
            try $0.delete(db)
          } catch {
            Failure
              .deleteFromPersistentStore(from: String(describing: type(of: self)), reason: "Unable to delete sync request: \(error)")
              .log()
          }
        }
      }
    } catch {
      Failure
      .deleteFromPersistentStore(from: String(describing: type(of: self)), reason: "Unable to delete sync requests: \(error)")
      .log()
    }
  }
}
