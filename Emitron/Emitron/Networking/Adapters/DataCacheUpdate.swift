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

typealias JSONEntityRelationships = (entity: EntityIdentity?, jsonRelationships: [JSONAPIRelationship])

struct DataCacheUpdate {
  let contents: [Content]
  let bookmarks: [Bookmark]
  let progressions: [Progression]
  let domains: [Domain]
  let groups: [Group]
  let categories: [Category]
  let contentCategories: [ContentCategory]
  let contentDomains: [ContentDomain]
  let relationships: [EntityRelationship]
  
  init(resources: [JSONAPIResource], relationships jsonEntityRelationships: [JSONEntityRelationships] = [JSONEntityRelationships]()) throws {
    self.relationships = DataCacheUpdate.relationships(from: resources, with: jsonEntityRelationships)
    contents = try resources
      .filter({ $0.type == "contents" })
      .map { try ContentAdapter.process(resource: $0, relationships: relationships) }
    bookmarks = try resources
      .filter({ $0.type == "bookmarks" })
      .map { try BookmarkAdapter.process(resource: $0, relationships: relationships) }
    progressions = try resources
      .filter({ $0.type == "progressions" })
      .map { try ProgressionAdapter.process(resource: $0, relationships: relationships) }
    domains = try resources
      .filter({ $0.type == "domains" })
      .map { try DomainAdapter.process(resource: $0, relationships: relationships) }
    groups = try resources
      .filter({ $0.type == "groups" })
      .map { try GroupAdapter.process(resource: $0, relationships: relationships) }
    categories = try resources
      .filter({ $0.type == "categories" })
      .map { try CategoryAdapter.process(resource: $0, relationships: relationships) }
    contentCategories = try ContentCategoryAdapter.process(relationships: relationships)
    contentDomains = try ContentDomainAdapter.process(relationships: relationships)
  }
  
  private static func relationships(from resources: [JSONAPIResource], with additionalRelationships: [JSONEntityRelationships]) -> [EntityRelationship] {
    var relationshipsToReturn = additionalRelationships.flatMap { (entityRelationship) -> [EntityRelationship] in
      guard let entityId = entityRelationship.entity else { return [EntityRelationship]() }
      return entityRelationships(from: entityRelationship.jsonRelationships, fromEntity: entityId)
    }
    relationshipsToReturn += resources.flatMap { (resource) -> [EntityRelationship] in
      guard let resourceEntityId = resource.entityId else { return [EntityRelationship]() }
      return entityRelationships(from: resource.relationships, fromEntity: resourceEntityId)
    }
    return relationshipsToReturn
  }
  
  private static func entityRelationships(from jsonRelationships: [JSONAPIRelationship], fromEntity: EntityIdentity) -> [EntityRelationship] {
    jsonRelationships.flatMap { (relationship) in
      relationship.data.compactMap { (resource) in
        guard let toEntity = resource.entityId else { return nil }
        return EntityRelationship(name: relationship.type,
                                  from: fromEntity,
                                  to: toEntity)
      }
    }
  }
}
