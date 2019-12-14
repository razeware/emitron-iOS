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
//

import Foundation
import CoreData

@objc(Content)
public class Content: NSManagedObject {
  static func transform(from model: ContentDetailsModel, viewContext: NSManagedObjectContext) -> Content {
    let contents = Content(context: viewContext)
    contents.update(from: model)
    return contents
  }
  
  static var displayableDownloads: NSFetchRequest<Content> {
    let request: NSFetchRequest<Content> = fetchRequest()
    let predicate = NSPredicate(format: "(contentType == collection OR contentType == screencast) AND download != NULL")
    let sort = NSSortDescriptor(key: "download.dateRequested", ascending: true)
    request.predicate = predicate
    request.sortDescriptors = [sort]
    return request
  }
  
  func update(from model: ContentDetailsModel) {
    id = Int64(model.id)
    name = model.name
    uri = model.uri
    desc = model.desc
    releasedAt = model.releasedAt
    free = model.free
    difficulty = model.difficulty?.rawValue
    contentTypeString = model.contentType?.rawValue
    duration = Int64(model.duration)
    bookmarked = model.bookmarked
    popularity = model.popularity
    cardArtworkUrl = model.cardArtworkURL
    technologyTripleString = model.technologyTripleString
    contributorString = model.contributorString
    videoID = Int64(model.videoID ?? 0)
  }
}

extension Content: DisplayableContent {
  var contentType: ContentType? {
    guard let contentTypeString = contentTypeString else { return nil }
    return ContentType(rawValue: contentTypeString)
  }
  
  var domainIDs: [Int64] {
    guard let domains = domains as? Set<Domain> else { return [] }
    return domains.map { $0.id }
  }
  
  var parentContentId: Int64? {
    parentContent?.id
  }
  
  var parentContent: DisplayableContent? {
    parentGroup?.parentContent
  }
  
  var isInCollection: Bool {
    parentGroup != nil
  }
}
