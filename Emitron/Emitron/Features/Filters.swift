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
  case none // For filters whose values aren't an array, for example the search query
  
  var initialFilters: Set<Filter> {
    switch self {
      
    case .platforms:
      let domains = DataManager.current.domainsMC.data
      let userFacingDomains = domains.filter { DomainLevel.userFacing.contains($0.level) }
      let domainTypes = userFacingDomains.map { (id: $0.id, name: $0.name) }
      
      return Set(Param.filters(for: [.domainTypes(types: domainTypes)]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .categories:
      let categories = DataManager.current.categoriesMC.data
      let categoryTypes = categories.map { (id: $0.id, name: $0.name) }
      
      return Set(Param.filters(for: [.categoryTypes(types: categoryTypes)]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .contentTypes:
      return Set(Param.filters(for: [.contentTypes(types: [.collection, .screencast, .episode])]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .difficulties:
      return Set(Param.filters(for: [.difficulties(difficulties: [.beginner, .intermediate, .advanced])]).map { Filter(groupType: self, param: $0, isOn: false ) })
    case .none:
      return Set()
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
    case .none:
      return ""
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
    // TODO: Check with Luke if we should have the Search filter here or not
    // It is convenient to be able to clear it from the applied filters control
    // But will also have to figure out how to connect the searchQuery + the AppliedFilter
    return filters.filter { $0.isOn }
  }
  
  var searchQuery: String? {
    didSet {
      guard let query = searchQuery else {
        // Remove search filter from filters
        if let searchFilter = searchFilter {
          filters.remove(searchFilter)
        }
        
        searchFilter = nil
        return
      }
      let filter = Filter(groupType: .none, param: Param.filter(for: .queryString(string: query)), isOn: !query.isEmpty)
      searchFilter = filter
      filters.update(with: filter)
    }
  }
  
  private var platforms: FilterGroup
  private var categories: FilterGroup
  private var contentTypes: FilterGroup
  private var difficulties: FilterGroup
  private var searchFilter: Filter?
  
  init() {
    self.platforms = FilterGroup(type: .contentTypes)
    self.categories = FilterGroup(type: .contentTypes)
    self.contentTypes = FilterGroup(type: .contentTypes)
    self.difficulties = FilterGroup(type: .contentTypes)
    self.filters = platforms.filters.union(categories.filters).union(contentTypes.filters).union(difficulties.filters)
  }
}
