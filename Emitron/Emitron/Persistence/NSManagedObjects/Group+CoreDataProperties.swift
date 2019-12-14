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


extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    @NSManaged public var desc: String?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var ordinal: Int64
    @NSManaged public var childContents: NSOrderedSet?
    @NSManaged public var parentContent: Content?

}

// MARK: Generated accessors for childContents
extension Group {

    @objc(insertObject:inChildContentsAtIndex:)
    @NSManaged public func insertIntoChildContents(_ value: Content, at idx: Int)

    @objc(removeObjectFromChildContentsAtIndex:)
    @NSManaged public func removeFromChildContents(at idx: Int)

    @objc(insertChildContents:atIndexes:)
    @NSManaged public func insertIntoChildContents(_ values: [Content], at indexes: NSIndexSet)

    @objc(removeChildContentsAtIndexes:)
    @NSManaged public func removeFromChildContents(at indexes: NSIndexSet)

    @objc(replaceObjectInChildContentsAtIndex:withObject:)
    @NSManaged public func replaceChildContents(at idx: Int, with value: Content)

    @objc(replaceChildContentsAtIndexes:withChildContents:)
    @NSManaged public func replaceChildContents(at indexes: NSIndexSet, with values: [Content])

    @objc(addChildContentsObject:)
    @NSManaged public func addToChildContents(_ value: Content)

    @objc(removeChildContentsObject:)
    @NSManaged public func removeFromChildContents(_ value: Content)

    @objc(addChildContents:)
    @NSManaged public func addToChildContents(_ values: NSOrderedSet)

    @objc(removeChildContents:)
    @NSManaged public func removeFromChildContents(_ values: NSOrderedSet)

}
