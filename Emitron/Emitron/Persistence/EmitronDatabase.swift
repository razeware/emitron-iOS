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

// swiftlint:disable identifier_name

/// A type responsible for initialising the appliation's database
enum EmitronDatabase {
  /// Creates a fully initialised database
  /// - Parameter path: Path at which to create the database
  static func openDatabase(atPath path: String) throws -> DatabasePool {
    // Connect to DB. Uses a pool for multi-threaded optimisations
    let dbPool = try DatabasePool(path: path)
    // Define the database schema
    try migrator.migrate(dbPool)
    
    return dbPool
  }
  
  /// Defines the schema of the database in a set of migrations
  static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("createContent") { db in
      try db.create(table: "content") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("uri", .text).unique().notNull().indexed()
        t.column("name", .text).notNull()
        t.column("descriptionHtml", .text).notNull()
        t.column("descriptionPlainText", .text).notNull()
        t.column("releasedAt", .datetime).notNull().indexed()
        t.column("free", .boolean).notNull().defaults(to: false)
        t.column("professional", .boolean).notNull().defaults(to: false)
        t.column("difficulty", .integer).notNull()
        t.column("contentType", .integer).notNull()
        t.column("duration", .integer).notNull().defaults(to: 0)
        t.column("videoIdentifier", .integer)
        t.column("cardArtworkUrl", .text)
        t.column("technologyTriple", .text).notNull()
        t.column("contributors", .text).notNull()
        t.column("ordinal", .integer).indexed()
      }
    }
    
    migrator.registerMigration("createBookmark") { db in
      try db.create(table: "bookmark") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("createdAt", .datetime).notNull()
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
      }
    }
    
    migrator.registerMigration("createProgression") { db in
      try db.create(table: "progression") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("target", .integer).notNull()
        t.column("progress", .integer).notNull()
        t.column("createdAt", .datetime).notNull()
        t.column("updatedAt", .datetime).notNull()
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
      }
    }
    
    migrator.registerMigration("createCategoryAndContentCategory") { db in
      try db.create(table: "category") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("name", .text).notNull()
        t.column("uri", .text).notNull()
        t.column("ordinal", .integer).notNull()
      }
      
      try db.create(table: "contentCategory") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
        t.column("categoryId", .integer).notNull().indexed().references("category", onDelete: .cascade)
      }
    }
    
    migrator.registerMigration("createDomainAndContentDomain") { db in
      try db.create(table: "domain") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("name", .text).notNull()
        t.column("slug", .text).notNull()
        t.column("description", .text)
        t.column("level", .integer).notNull()
        t.column("ordinal", .integer).notNull()
      }
      
      try db.create(table: "contentDomain") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
        t.column("domainId", .integer).notNull().indexed().references("domain", onDelete: .cascade)
      }
    }
    
    migrator.registerMigration("createGroup") { db in
      try db.create(table: "group") { t in
        t.column("id", .integer).primaryKey().notNull()
        t.column("name", .text).notNull()
        t.column("description", .text)
        t.column("ordinal", .integer).notNull()
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
      }
      
      try db.alter(table: "content") { t in
        t.add(column: "groupId", .integer).indexed().references("group", onDelete: .setNull)
      }
    }
    
    migrator.registerMigration("createDownload") { db in
      try db.create(table: "download") { t in
        t.column("id", .text).primaryKey()
        t.column("requestedAt", .datetime).notNull().indexed()
        t.column("lastValidatedAt", .datetime)
        t.column("fileName", .text)
        t.column("remoteUrl", .text)
        t.column("progress", .double).notNull().defaults(to: 0)
        t.column("state", .integer).notNull().defaults(to: 0)
        t.column("contentId", .integer).notNull().indexed().references("content", onDelete: .cascade)
      }
    }
    
    migrator.registerMigration("createSyncRequest") { db in
      try db.create(table: "syncRequest") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("contentId", .integer).notNull().indexed()
        t.column("associatedRecordId", .integer).indexed()
        t.column("category", .integer).notNull().indexed()
        t.column("type", .integer).notNull().indexed()
        t.column("date", .datetime).notNull()
        t.column("attributes", .text).notNull()
      }
    }
    
    migrator.registerMigration("addOrdinalToDownload") { db in
      try db.alter(table: "download", body: { t in
        t.add(column: "ordinal", .integer).notNull().defaults(to: 0)
      })
    }
    
    //: Add future migrations below here, to ensure consistency
    
    return migrator
  }
}
