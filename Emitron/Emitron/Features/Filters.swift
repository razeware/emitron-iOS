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
import SwiftUI
import Combine

enum Platform: Int, CaseIterable {
  case iOSandSwift = 1
  case androidAndKotlin
  case serverSideSwift
  case unity
  case unrealEngine
  case macOS
  case archive
}

struct FilterGroup: Hashable {
  var type: FilterGroupType
  var filters: Set<Filter>
  var numApplied: Int {
    return filters.filter { $0.isOn }.count
  }
  
  init(type: FilterGroupType) {
    self.type = type
    self.filters = type.initialFilters
  }
}

enum FilterGroupType: CaseIterable {
  case platforms
  case categories
  case contentTypes
  case difficulties
  
  var initialFilters: Set<Filter> {
    switch self {
      
    case .platforms:
      // TODO: These are hardcoded atm, but will come from the PersistenceStore cache, once that's there
      let domainTypes = [(id: 1, name: "iOS & Swift"),
                         (id: 2, name: "Android & Kotlin"),
                         (id: 8, name: "Server-side Swift"),
                         (id: 3, name: "Unity"),
                         (id: 4, name: "Unreal Engine")]
      
      return Set(Param.filter(by: [.domainTypes(types: domainTypes)]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .categories:
      // TODO: These are hardcoded atm, but will come from the PersistenceStore cache, once that's there
      let categoryTypes = [(id: 156, name: "Algorithms & Data Structures"),
                           (id: 181, name: "Architecture"),
                           (id: 159, name: "AR / VR"),
                           (id: 157, name: "Audio / Video"),
                           (id: 151, name: "Concurrency")]
      
      return Set(Param.filter(by: [.categoryTypes(types: categoryTypes)]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .contentTypes:
      return Set(Param.filter(by: [.contentTypes(types: [.collection, .screencast, .episode])]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .difficulties:
      return Set(Param.filter(by: [.difficulties(difficulties: [.beginner, .intermediate, .advanced])]).map { Filter(groupType: self, param: $0, isOn: false ) })
    }
  }
  
  var name: String {
    switch self {
    case .contentTypes:
      return "Content Type"
    case .platforms:
      return "Platforms"
    case .categories:
      return "Categories"
    case .difficulties:
      return "Difficulties"
    }
  }
}

class Filters: ObservableObject {
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  
  var filters: Set<Filter> {
    didSet {
      platforms.filters = filters.filter { $0.groupType == .platforms }
      categories.filters = filters.filter { $0.groupType == .categories }
      contentTypes.filters = filters.filter { $0.groupType == .contentTypes }
      difficulties.filters = filters.filter { $0.groupType == .difficulties }
      objectWillChange.send(())
    }
  }
  
  var filterGroups: [FilterGroup] {
      return [platforms, categories, contentTypes, difficulties]
    }
  
  var appliedParameters: [Parameter] {
    return appliedFilters.map { $0.parameter }
  }
  
  var appliedFilters: [Filter] {
    return filters.filter { $0.isOn }
  }
  
  private var platforms: FilterGroup
  private var categories: FilterGroup
  private var contentTypes: FilterGroup
  private var difficulties: FilterGroup
  
  init() {
    self.platforms = FilterGroup(type: .platforms)
    self.categories = FilterGroup(type: .categories)
    self.contentTypes = FilterGroup(type: .contentTypes)
    self.difficulties = FilterGroup(type: .difficulties)
    self.filters = platforms.filters.union(categories.filters).union(contentTypes.filters).union(difficulties.filters)
  }
}
