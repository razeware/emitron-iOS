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
  /// Return a list of all **Category** objects in the data store
  func categoryList() throws -> [Category] {
    try db.read { db in
      try Category
        .order(Category.Columns.name.asc)
        .fetchAll(db)
    }
  }
  
  /// Get all the **Category** objects with the given keys
  func categories(with categoryIds: [Int]) throws -> [Category] {
    try db.read { db in
      try Category
        .fetchAll(db, keys: categoryIds)
        .sorted { $0.ordinal <= $1.ordinal }
    }
  }
}

// MARK: - Data writing methods
extension PersistenceStore {
  
  /// Sync the **Category** list with the data store
  /// - Parameter categories: The list of **Category** objects to sync
  func sync(categories: [Category]) throws {
    try db.write { db in
      // Delete categories that no longer exist
      try Category
        .filter(!categories.map(\.id).contains(Category.Columns.id))
        .deleteAll(db)
      // And now save all the categories we've been provided
      try categories.forEach { try $0.save(db) }
    }
  }
}
