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

// Parameter Values
enum ContentDifficulty: Int, Codable, CaseIterable {
  case beginner
  case intermediate
  case advanced
  case allLevels
  
  init?(string: String) {
    switch string {
    case "beginner":
      self = .beginner
    case "intermediate":
      self = .intermediate
    case "advanced":
      self = .advanced
    default:
      return nil
    }
  }
  
  var displayString: String {
    switch self {
    case .beginner:
      return "Beginner"
    case .intermediate:
      return "Intermediate"
    case .advanced:
      return "Advanced"
    case .allLevels:
      return "All Levels"
    }
  }
  
  var requestValue: String {
    switch self {
    case .beginner:
      return "beginner"
    case .intermediate:
      return "intermediate"
    case .advanced:
      return "advanced"
    case .allLevels:
      return ""
    }
  }
  
  var sortOrdinal: Int {
    switch self {
    case .beginner:
      return 0
    case .intermediate:
      return 1
    case .advanced:
      return 2
    case .allLevels:
      return 3
    }
  }
}

enum ContentType: Int, Codable {
  case collection
  case episode
  case screencast
  case article
  case product
  
  init?(string: String) {
    switch string {
    case "collection":
      self = .collection
    case "episode":
      self = .episode
    case "screencast":
      self = .screencast
    case "article":
      self = .article
    case "product":
      self = .product
    default:
      return nil
    }
  }
  
  var displayString: String {
    switch self {
    case .collection:
      return "Video Course"
    case .episode:
      return "Episode"
    case .screencast:
      return "Screencast"
    case .article:
      return "Article"
    case .product:
      return "Book"
    }
  }
  
  var requestValue: String {
    switch self {
    case .collection:
      return "collection"
    case .episode:
      return "episode"
    case .screencast:
      return "screencast"
    case .article:
      return "article"
    case .product:
      return "product"
    }
  }
  
  var sortOrdinal: Int {
    switch self {
    case .collection:
      return 0
    case .screencast:
      return 1
    case .episode:
      return 2
    case .article:
      return 3
    case .product:
      return 4
    }
  }
}

extension Int {
  static let defaultPageNum = 20
  static let maxPageNum = 100
}

enum CompletionStatus: String {
  case inProgress = "in_progress"
  case completed
}

// Parameter Keys
enum ParameterKey {
  case pageNumber(number: Int)
  case pageSize(size: Int)
  
  var strKey: String {
    switch self {
    case .pageNumber:
      return "page[number]"
    case .pageSize:
      return "page[size]"
    }
  }
  
  var value: String {
    switch self {
    case .pageNumber(let number):
      return "\(number)"
    case .pageSize(let size):
      return "\(size)"
    }
  }
  
  var param: Parameter {
    // TODO: This might need to be re-implemented
    return Parameter(key: self.strKey,
                     value: self.value,
                     displayName: "",
                     sortOrdinal: 0)
  }
}

enum ParameterFilterValue {
  case contentTypes(types: [ContentType]) // An array containing ContentType strings
  case domainTypes(types: [(id: Int, name: String, sortOrdinal: Int)]) // An array of numerical IDs of the domains you are interested in.
  case categoryTypes(types: [(id: Int, name: String, sortOrdinal: Int)]) // An array of numberical IDs of the categories you are interested in.
  case difficulties(difficulties: [ContentDifficulty]) // An array populated with ContentDifficulty options
  case contentIds(ids: [Int])
  case queryString(string: String)
  case completionStatus(status: CompletionStatus)
  
  var strKey: String {
    switch self {
    case .contentTypes:
      return "content_types"
    case .domainTypes:
      return "domain_ids"
    case .categoryTypes:
      return "category_ids"
    case .difficulties:
      return "difficulties"
    case .contentIds:
      return "content_ids"
    case .queryString:
      return "q"
    case .completionStatus:
      return "completion_status"
    }
  }
  
  var values: [(displayName: String, requestValue: String, ordinal: Int)] {
    switch self {
    case .contentTypes(types: let types):
      return types.map { (displayName: $0.displayString, requestValue: $0.requestValue, ordinal: $0.sortOrdinal) }
    case .domainTypes(types: let types):
      return types.map { (displayName: $0.name, requestValue: "\($0.id)", ordinal: $0.sortOrdinal) }
    case .categoryTypes(types: let types):
      return types.map { (displayName: $0.name, requestValue: "\($0.id)", ordinal: $0.sortOrdinal) }
    case .difficulties(difficulties: let difficulties):
      return difficulties.map { (displayName: $0.displayString, requestValue: $0.requestValue, ordinal: $0.sortOrdinal) }
    case .contentIds(ids: let ids):
      return ids.map { (displayName: "\($0)", requestValue: "\($0)", ordinal: 0) }
    case .queryString(string: let str):
      return [(displayName: str, requestValue: str, ordinal: 0)]
    case .completionStatus(let status):
      return [(displayName: status.rawValue, requestValue: status.rawValue, ordinal: 0)]
    }
  }
    
  var isSearchQuery: Bool {
    switch self {
    case .queryString:
      return true
    case .contentIds,
         .contentTypes,
         .domainTypes,
         .difficulties,
         .categoryTypes,
         .completionStatus:
      return false
    }
  }
  
  var value: String {
    switch self {
    case .queryString(let str):
      return str
    case .completionStatus(let status):
      return status.rawValue
    case .contentIds,
         .contentTypes,
         .domainTypes,
         .difficulties,
         .categoryTypes:
      return ""
    }
  }
}

//sort=-released_at; reversechronological order
enum ParameterSortValue: String, Codable {
  case popularity = "popularity"
  case releasedAt = "released_at"
  case updatedAt = "updated_at"
}

// filter[content_types][]=collection&filter[content_types][]=screencast
// typealias Parameter = (key: String, value: String)
// Changing this to a struct, so that I can conform it to equatable

struct Parameter: Hashable, Codable {
  let key: String
  let value: String
  let displayName: String
  let sortOrdinal: Int
}

enum Param {
    
  // Not to be used for the search query filter
  static func filters(for values: [ParameterFilterValue]) -> [Parameter] {
    var allParams: [Parameter] = []
    
    values.forEach { value in
      guard !value.isSearchQuery else { return }
      
      let key = "filter[\(value.strKey)][]"
      let values = value.values
      let all = values.map { Parameter(key: key, value: $0.requestValue, displayName: $0.displayName, sortOrdinal: $0.ordinal) }
      
      allParams.append(contentsOf: all)
    }
    
    return allParams
  }
    
  // Only to be used for the search query filter
  static func filter(for param: ParameterFilterValue) -> Parameter {
    Parameter(key: "filter[\(param.strKey)]", value: param.value, displayName: param.value, sortOrdinal: 0)
  }
  
  static func sort(for value: ParameterSortValue,
                   descending: Bool) -> Parameter {
    let key =  "sort"
    let value = "\(descending ? "-" : "")\(value.rawValue)"
    
    return Parameter(key: key, value: value, displayName: "Sort", sortOrdinal: 0)
  }
}
