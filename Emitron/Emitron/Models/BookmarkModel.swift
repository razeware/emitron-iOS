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

class BookmarkModel {

  // MARK: - Properties
  private(set) var id: Int = 0

  //TODO Something funny going on with dates in Xcode 11! when you mark them as optional they'll always say they're nil
  // Does not happen in Xcode 10
  private(set) var createdAt: Date
  private(set) var content: ContentDetailsModel?

  // MARK: - Initializers
  init?(resource: JSONAPIResource,
        metadata: [String: Any]?) {
    self.id = resource.id

    if let createdAtStr = resource["created_at"] as? String {
      self.createdAt = DateFormatter.apiDateFormatter.date(from: createdAtStr) ?? Date()
    } else {
      self.createdAt = Date()
    }
    
    for relationship in resource.relationships {
      switch relationship.type {
      case "content":
        let ids = relationship.data.compactMap { $0.id }
        let included = resource.parent?.included.filter { ids.contains($0.id) }
        // TODO: Fix tthee crash, so we don't have to do a double transformation
        let includedContent = included?.compactMap { ContentSummaryModel($0, metadata: $0.meta) }
        let detailsContent = includedContent?.compactMap { ContentDetailsModel(summaryModel: $0) }
        if let content = detailsContent?.first {
          self.content = content
        }
        
      default:
        break
      }
    }
  }
  
  /// Convenience initializer to transform core data **Domain** into a **DomainModel**
  ///
  /// - parameters:
  ///   - domain: core data entity to transform into domain model
  init(_ bookmark: Bookmark) {
    self.id = bookmark.id.intValue
    self.createdAt = bookmark.createdAt
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
