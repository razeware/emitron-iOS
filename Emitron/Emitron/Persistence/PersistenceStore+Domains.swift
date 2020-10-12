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

// MARK: - Data reading methods for display
extension PersistenceStore {
  /// List of all the **Domain** objects from the data store
  func domainList() throws -> [Domain] {
    try db.read { db in
      try Domain
        .order(Domain.Columns.level.asc)
        .fetchAll(db)
    }
  }
  
  /// Get all the **Domain** objects with the given keys
  func domains(with domainIds: [Int]) throws -> [Domain] {
    try db.read { db in
      try Domain
        .fetchAll(db, keys: domainIds)
        .sorted { $0.level.rawValue <= $1.level.rawValue }
    }
  }
}

// MARK: - Data writing methods
extension PersistenceStore {
  /// Sync all **Domain** objects to the data store
  /// - Parameter domains: The list of **Domain** objects to sync
  func sync(domains: [Domain]) throws {
    try db.write { db in
      // Delete domains that no longer exist
      try Domain
        .filter(!domains.map(\.id).contains(Domain.Columns.id))
        .deleteAll(db)
      // And now save all the domains we've been provided
      try domains.forEach { try $0.save(db) }
    }
  }
}
