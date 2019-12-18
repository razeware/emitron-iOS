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
import SwiftyJSON

class BookmarkModel: ContentRelatable {
  
  var type: ContentRelationship = .bookmark

  // MARK: - Properties
  let id: Int

  //TODO Something funny going on with dates in Xcode 11! when you mark them as optional they'll always say they're nil
  // Does not happen in Xcode 10
  private(set) var createdAt: Date?
  let contentId: Int
  private(set) var content: ContentDetailsModel?

  // MARK: - Initializers
  init?(resource: JSONAPIResource, metadata: [String: Any]?) {
    self.id = resource.id
    guard let contentId = resource.relationships.first(where: { $0.type == "content" })?.data.first?.id else { return nil }
    self.contentId = contentId

    if let createdAtStr = resource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }

    var relationships: [ContentRelatable] = [self]
    var progression: ProgressionModel?
    
    for relationship in resource.relationships {
      switch relationship.type {
      case "content":
        let ids = relationship.data.compactMap { $0.id }
        let included = resource.parent?.included.filter { ids.contains($0.id) }
        
        if let includedRelationships = included?.first?.relationships {
          for rel in includedRelationships {
            switch rel.type {
            case "progression":
              let ids = relationship.data.compactMap { $0.id }
              let included = resource.parent?.included.filter { ids.contains($0.id) }
              let progressions = included?.compactMap { ProgressionModel($0, metadata: $0.meta) }
              progression = progressions?.first
              
            default: break
            }
          }
        }
        
        self.content = included?.compactMap { ContentDetailsModel($0, metadata: $0.meta) }.first
        
      default:
        break
      }
      
      if let progression = progression {
        relationships.append(progression)
      }
      self.content?.addRelationships(for: relationships)
    }
  }
  
  init(id: Int, contentId: Int) {
    self.id = id
    self.contentId = contentId
  }
  
  /// Convenience initializer to transform persisted **Bookmark** into a **BookmarkModel**
  ///
  /// - parameters:
  ///   - bookmark: persisted entity to transform into bookmark model
  init(_ bookmark: Bookmark) {
    self.id = bookmark.id
    self.createdAt = bookmark.createdAt
    self.contentId = bookmark.contentId
  }
}

extension BookmarkModel {
  static var test: [BookmarkModel] {
    do {
      let fileURL = Bundle.main.url(forResource: "BookmarksModelTest", withExtension: "json")
      let data = try Data(contentsOf: fileURL!)
      let json = try JSON(data: data)
    
      let document = JSONAPIDocument(json)
      let bookmarks = document.data.compactMap { BookmarkModel(resource: $0, metadata: nil) }
      return bookmarks
    } catch {
      return []
    }
  }
}
