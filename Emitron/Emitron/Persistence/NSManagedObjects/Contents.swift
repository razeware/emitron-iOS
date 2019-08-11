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

import CoreData
import Foundation

@objc(Contents)
final class Contents: NSManagedObject {

  @nonobjc class func fetchRequest() -> NSFetchRequest<Contents> {
    return NSFetchRequest<Contents>(entityName: "Contents")
  }

  @NSManaged var id: NSNumber
  @NSManaged var name: String
  @NSManaged var uri: String
  @NSManaged var desc: String
  @NSManaged var releasedAt: Date
  @NSManaged var free: Bool
  @NSManaged var difficulty: String
  @NSManaged var contentType: String
  @NSManaged var duration: NSNumber
  @NSManaged var popularity: Double
  @NSManaged var bookmarked: Bool
  @NSManaged var cardArtworkUrl: String?
  @NSManaged var technologyTripleString: String
  @NSManaged var contributorString: String
  @NSManaged var videoID: NSNumber
  
  static func transform(from model: ContentDetailModel, viewContext: NSManagedObjectContext) -> Contents {
    let contents = Contents(context: viewContext)
    contents.id = NSNumber(value: model.id)
    contents.name = model.name
    contents.uri = model.uri
    contents.desc = model.description
    contents.releasedAt = model.releasedAt
    contents.free = model.free
    contents.difficulty = model.difficulty.rawValue
    contents.contentType = model.contentType.rawValue
    contents.duration = NSNumber(value: model.duration)
    contents.bookmarked = model.bookmarked
    contents.popularity = model.popularity
    contents.cardArtworkUrl = model.cardArtworkURL?.absoluteString
    contents.technologyTripleString = model.technologyTripleString
    contents.contributorString = model.contributorString
    contents.videoID = NSNumber(value: model.videoID)
    return contents
  }
}
