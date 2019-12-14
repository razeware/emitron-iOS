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


extension Content {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Content> {
        return NSFetchRequest<Content>(entityName: "Content")
    }

    @NSManaged public var bookmarked: Bool
    @NSManaged public var cardArtworkUrl: URL?
    @NSManaged public var contentTypeString: String?
    @NSManaged public var contributorString: String?
    @NSManaged public var desc: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var duration: Int64
    @NSManaged public var free: Bool
    @NSManaged public var id: Int64
    @NSManaged public var index: Int64
    @NSManaged public var name: String?
    @NSManaged public var popularity: Double
    @NSManaged public var releasedAt: Date?
    @NSManaged public var technologyTripleString: String?
    @NSManaged public var uri: String?
    @NSManaged public var videoID: Int64
    @NSManaged public var childGroups: NSOrderedSet?
    @NSManaged public var download: Download?
    @NSManaged public var parentGroup: Group?
    @NSManaged public var progression: Progression?
    @NSManaged public var domains: NSSet?
    @NSManaged public var categories: NSSet?
    @NSManaged public var bookmark: Bookmark?

}

// MARK: Generated accessors for childGroups
extension Content {

    @objc(insertObject:inChildGroupsAtIndex:)
    @NSManaged public func insertIntoChildGroups(_ value: Group, at idx: Int)

    @objc(removeObjectFromChildGroupsAtIndex:)
    @NSManaged public func removeFromChildGroups(at idx: Int)

    @objc(insertChildGroups:atIndexes:)
    @NSManaged public func insertIntoChildGroups(_ values: [Group], at indexes: NSIndexSet)

    @objc(removeChildGroupsAtIndexes:)
    @NSManaged public func removeFromChildGroups(at indexes: NSIndexSet)

    @objc(replaceObjectInChildGroupsAtIndex:withObject:)
    @NSManaged public func replaceChildGroups(at idx: Int, with value: Group)

    @objc(replaceChildGroupsAtIndexes:withChildGroups:)
    @NSManaged public func replaceChildGroups(at indexes: NSIndexSet, with values: [Group])

    @objc(addChildGroupsObject:)
    @NSManaged public func addToChildGroups(_ value: Group)

    @objc(removeChildGroupsObject:)
    @NSManaged public func removeFromChildGroups(_ value: Group)

    @objc(addChildGroups:)
    @NSManaged public func addToChildGroups(_ values: NSOrderedSet)

    @objc(removeChildGroups:)
    @NSManaged public func removeFromChildGroups(_ values: NSOrderedSet)

}

// MARK: Generated accessors for domains
extension Content {

    @objc(addDomainsObject:)
    @NSManaged public func addToDomains(_ value: Domain)

    @objc(removeDomainsObject:)
    @NSManaged public func removeFromDomains(_ value: Domain)

    @objc(addDomains:)
    @NSManaged public func addToDomains(_ values: NSSet)

    @objc(removeDomains:)
    @NSManaged public func removeFromDomains(_ values: NSSet)

}

// MARK: Generated accessors for categories
extension Content {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}
