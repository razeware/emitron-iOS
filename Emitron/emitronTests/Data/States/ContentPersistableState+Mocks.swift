// Copyright (c) 2022 Kodeco Inc

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
  init(content: Content, cacheUpdate: DataCacheUpdate) {
    let groups = cacheUpdate.groups.filter { $0.contentID == content.id }
    self.init(
      content: content,
      contentDomains: cacheUpdate.contentDomains.filter({ $0.contentID == content.id }),
      contentCategories: cacheUpdate.contentCategories.filter({ $0.contentID == content.id }),
      bookmark: cacheUpdate.bookmarks.first(where: { $0.contentID == content.id }),
      parentContent: content.groupID.flatMap { groupID in
        // There must be parent content
        cacheUpdate.groups.first { $0.id == groupID }
          .flatMap { parentGroup in
            cacheUpdate.contents.first { $0.id == parentGroup.contentID }
          }
      },
      progression: (cacheUpdate.progressions.first { $0.contentID == content.id }),
      groups: groups,
      childContents: cacheUpdate.contents.filter {
        groups.map(\.id).contains($0.groupID ?? -1)
      }
    )
  }

  init(contentID: Int, cacheUpdate: DataCacheUpdate) {
    guard let content = (cacheUpdate.contents.first { $0.id == contentID })
    else { preconditionFailure("Invalid cache update") }

    self.init(content: content, cacheUpdate: cacheUpdate)
  }
}
