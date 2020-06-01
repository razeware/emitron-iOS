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

@testable import Emitron

extension ContentPersistableState {
  static func persistableState(for content: Content, with cacheUpdate: DataCacheUpdate) -> ContentPersistableState {
    persistableState(for: content.id, with: cacheUpdate)
  }
  
  static func persistableState(for contentId: Int, with cacheUpdate: DataCacheUpdate) -> ContentPersistableState {
    
    guard let content = cacheUpdate.contents.first(where: { $0.id == contentId }) else { preconditionFailure("Invalid cache update") }
    
    var parentContent: Content?
    if let groupId = content.groupId {
      // There must be parent content
      if let parentGroup = cacheUpdate.groups.first(where: { $0.id == groupId }) {
        parentContent = cacheUpdate.contents.first { $0.id == parentGroup.contentId }
      }
    }
    
    let groups = cacheUpdate.groups.filter { $0.contentId == content.id }
    let groupIds = groups.map(\.id)
    let childContent = cacheUpdate.contents.filter { groupIds.contains($0.groupId ?? -1) }
    
    return ContentPersistableState(
      content: content,
      contentDomains: cacheUpdate.contentDomains.filter({ $0.contentId == content.id }),
      contentCategories: cacheUpdate.contentCategories.filter({ $0.contentId == content.id }),
      bookmark: cacheUpdate.bookmarks.first(where: { $0.contentId == content.id }),
      parentContent: parentContent,
      progression: cacheUpdate.progressions.first(where: { $0.contentId == content.id }),
      groups: groups,
      childContents: childContent
    )
  }
}
