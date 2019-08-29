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
  
  init(type: FilterGroupType, filters: Set<Filter> = []) {
    self.type = type
    self.filters = filters
  }
}

enum FilterGroupType: String, Hashable, CaseIterable, Codable {
  case platforms = "Platforms"
  case categories = "Categories"
  case contentTypes = "Content Type"
  case difficulties = "Difficulties"
  case none = "" // For filters whose values aren't an array, for example the search query
  
  var name: String {
    return self.rawValue
  }
}

enum SortFilter: Int, Codable {
  case newest
  case popularity
  
  var next: SortFilter {
    switch self {
    case .newest:
      return .popularity
    case .popularity:
      return .newest
    }
  }
  
  var name: String {
    switch self {
    case .newest:
      return Constants.newest
    case .popularity:
      return Constants.popularity
    }
  }
  
  var paramValue: ParameterSortValue {
    switch self {
    case .newest:
      return .releasedAt
    case .popularity:
      return .popularity
    }
  }
  
  var parameter: Parameter {
    return Param.sort(for: paramValue, descending: true)
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
    }
  }
  
  var filterGroups: [FilterGroup] {
      return [platforms, categories, contentTypes, difficulties]
    }
  
  var appliedParameters: [Parameter] {
    var filterParameters = appliedFilters.map { $0.parameter }
    let appliedContentFilters = contentTypes.filters.filter { $0.isOn }
    
    if appliedContentFilters.isEmpty {
      // Add default filters
      filterParameters.append(contentsOf: defaultFilters.map { $0.parameter })
    }
    
    var appliedParameters = filterParameters + [sortFilter.parameter]
    
    if let searchFilter = searchFilter {
      appliedParameters.append(searchFilter.parameter)
    }
    
    return appliedParameters
  }
  
  var appliedFilters: [Filter] {
    // TODO: Check with Luke if we should have the Search filter here or not
    // It is convenient to be able to clear it from the applied filters control
    // But will also have to figure out how to connect the searchQuery + the AppliedFilter
    return filters.filter { $0.isOn }
  }
  
  // The  default filters to always apply, unless the user selects them, are .collection and .screencast
  // If the user makes a selection on ANY of them for the contentTypes group, only apply those
  // They can only select between .collection, .screencast and .episode
  var defaultFilters: [Filter] {
    let contentFilters = Set(Param.filters(for: [.contentTypes(types: [.collection, .screencast])]).map { Filter(groupType: .contentTypes, param: $0, isOn: true ) })
    
    return Array(contentFilters)
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
    }
  }
  
  private(set) var sortFilter: SortFilter
  private(set) var platforms: FilterGroup
  private(set) var categories: FilterGroup
  private(set) var contentTypes: FilterGroup
  private(set) var difficulties: FilterGroup
  private(set) var searchFilter: Filter?
  
  private var defaultParameters: [Parameter] {
    let sortParam = Param.sort(for: .releasedAt, descending: true)
    let contentFilters = Set(Param.filters(for: [.contentTypes(types: [.collection, .screencast])]).map { Filter(groupType: .contentTypes, param: $0, isOn: true ) })
    
    var contentParams = FilterGroup(type: .contentTypes, filters: contentFilters).filters.map { $0.parameter }
    contentParams.append(sortParam)
    
    return contentParams
  }
  
  init() {

    self.platforms = FilterGroup(type: .platforms)
    self.categories = FilterGroup(type: .categories)
    
    let contentFilters = Set(Param.filters(for: [.contentTypes(types: [.collection, .screencast, .episode])]).map { Filter(groupType: .contentTypes, param: $0, isOn: false ) })
    self.contentTypes = FilterGroup(type: .contentTypes, filters: contentFilters)
    
    let difficultyFilters = Set(Param.filters(for: [.difficulties(difficulties: [.beginner, .intermediate, .advanced])]).map { Filter(groupType: .difficulties, param: $0, isOn: false ) })
    self.difficulties = FilterGroup(type: .difficulties, filters: difficultyFilters)
    
    self.sortFilter = SortFilter.newest
    
    // 1. Check if there are filters in UserDefaults
    let savedFilters = UserDefaults.standard.filters
    // 2. Check whether the types of filters in UserDefaults still match the types of filters possible on the BE and sync them
    // 3. Dissementae userfilters into the appropriate filter categories
    if !savedFilters.isEmpty {
      self.platforms.filters = savedFilters.filter { $0.groupType == .platforms }
      self.categories.filters = savedFilters.filter { $0.groupType == .categories }
      self.contentTypes.filters = savedFilters.filter { $0.groupType == .contentTypes }
      self.difficulties.filters = savedFilters.filter { $0.groupType == .difficulties }
    }
    // 3. If there are filters stored in UserDefaults, use those
    // 4. If there are no filters stores in UserDefaults, use the default filters and parameters
    
    let freshFilters = platforms.filters.union(categories.filters).union(contentTypes.filters).union(difficulties.filters).union(platforms.filters)
    self.filters = freshFilters
    
    // 1. Check if there is a sort in UserDefaults and use that
    let savedSort = UserDefaults.standard.sort
    self.sortFilter = savedSort
  }
  
  func updatePlatformFilters(for domainModels: [DomainModel]) {
    let userFacingDomains = domainModels.filter { DomainLevel.userFacing.contains($0.level) }
    let domainTypes = userFacingDomains.map { (id: $0.id, name: $0.name) }
    let platformFilters = Set(Param.filters(for: [.domainTypes(types: domainTypes)]).map { Filter(groupType: .platforms, param: $0, isOn: false ) })
    platforms.filters = platformFilters
    
    filters = filters.union(platforms.filters)
  }
  
  func updateCategoryFilters(for categoryModels: [CategoryModel]) {
    let categoryTypes = categoryModels.map { (id: $0.id, name: $0.name) }
    let categoryFilters = Set(Param.filters(for: [.categoryTypes(types: categoryTypes)]).map { Filter(groupType: .categories, param: $0, isOn: false ) })
    categories.filters = categoryFilters
    filters = filters.union(categories.filters)
  }
  
  func removeAll() {
    appliedFilters.forEach {
      var filter = $0 // Creating an intermediary var, because we can't mutate $0 (immutable)
      filter.toggle(to: false)
      filters.remove($0)
      filters.update(with: filter)
    }
  }
  
  func changeSortFilter() {
    sortFilter = sortFilter.next
    UserDefaults.standard.updateSort(with: sortFilter)
    objectWillChange.send(())
  }
  
  func commitUpdates() {
    UserDefaults.standard.updateFilters(with: self)
    objectWillChange.send(())
  }
}

extension Filter {
  func saveToUserDefaults() {
    //UserDefaults.standard.updateFilters(with: self)
  }
  
  func restoreFromUserDefaults() {
    
  }
}