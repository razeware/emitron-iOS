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
enum ContentDifficulty: String {
  case beginner
  case intermediate
  case advanced
}

enum ContentType: String {
  case collection
  case episode
  case screencast
  case article
  case product
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
  case completionStatus(status: CompletionStatus)
  case pageNumber(number: Int)
  case pageSize(size: Int)

  var strKey: String {
    switch self {
    case .completionStatus:
      return "completion_status"
    case .pageNumber:
      return "page[number]"
    case .pageSize:
      return "page[size]"
    }
  }

  var value: String {
    switch self {
    case .completionStatus(status: let status):
      return status.rawValue
    case .pageNumber(let number):
      return "\(number)"
    case .pageSize(let size):
      return "\(size)"
    }
  }

  var param: Parameter {
    return Parameter(key: self.strKey, value: self.value)
  }
}

enum ParameterFilterValue {
  case contentTypes(types: [ContentType]) // An array containing ContentType strings
  case domainIds(ids: [Int]) // An array of numerical IDs of the domains you are interested in.
  case categoryIds(ids: [Int]) // An array of numberical IDs of the categories you are interested in.
  case difficulties(difficulties: [ContentDifficulty]) // An array populated with ContentDifficulty options
  case contentIds(ids: [Int])

  var strKey: String {
    switch self {
    case .contentTypes:
      return "content_types"
    case .domainIds:
      return "domain_ids"
    case .categoryIds:
      return "category_ids"
    case .difficulties:
      return "difficulties"
    case .contentIds:
      return "content_ids"
    }
  }

  var values: [String] {
    switch self {
    case .contentTypes(types: let types):
      return types.map { $0.rawValue }
    case .domainIds(ids: let ids):
      return ids.map { "\($0)" }
    case .categoryIds(ids: let ids):
      return ids.map { "\($0)" }
    case .difficulties(difficulties: let difficulties):
      return difficulties.map { $0.rawValue }
    case .contentIds(ids: let ids):
      return ids.map { "\($0)" }
    }
  }
}

//sort=-released_at; reversechronological order
enum ParameterSortValue: String {
  case popularity = "popularity"
  case releasedAt = "released_at"
}

// filter[content_types][]=collection&filter[content_types][]=screencast
typealias Parameter = (key: String, value: String)

enum Param {

  static func filter(by values: [ParameterFilterValue]) -> [Parameter] {
    var allParams: [Parameter] = []

    values.forEach { value in

      let key = "filter[\(value.strKey)][]"
      let values = value.values
      let all = values.map { Parameter(key: key, value: $0) }

      allParams.append(contentsOf: all)
    }

    return allParams
  }

  static func sort(by value: ParameterSortValue, descending: Bool) -> Parameter {
    let key =  "sort"
    let value = "\(descending ? "-" : "")\(value.rawValue)"

    return Parameter(key: key, value: value)
  }
}
