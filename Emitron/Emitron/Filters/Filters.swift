// Copyright (c) 2019 Razeware LLC
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

import Combine

class Filters: ObservableObject {
  @Published var searchStr: String = ""
  var all: Set<Filter> {
    didSet {
      let sortedFilters =
        Dictionary(grouping: all, by: \.groupType)
        .mapValues { $0.sorted() }
      
      platforms.filters = sortedFilters[.platforms] ?? []
      categories.filters = sortedFilters[.categories] ?? []
      contentTypes.filters = sortedFilters[.contentTypes] ?? []
      difficulties.filters = sortedFilters[.difficulties] ?? []
      subscriptionPlans.filters = sortedFilters[.subscriptionPlans] ?? []
    }
  }
  
  // This decides the order in which the filter groups are displayed
  var filterGroups: [FilterGroup] {
    [
      platforms,
      subscriptionPlans,
      contentTypes,
      difficulties,
      categories
    ]
  }
  
  var appliedParameters: [Parameter] {
    var filterParameters = applied.map(\.parameter)
    let appliedContentFilters = contentTypes.filters.filter(\.isOn)
    
    if appliedContentFilters.isEmpty {
      // Add default filters
      filterParameters.append(contentsOf: self.defaultFilters.map(\.parameter))
    }
    
    var appliedParameters = filterParameters + [sortFilter.parameter]
    
    if let searchFilter = searchFilter {
      appliedParameters.append(searchFilter.parameter)
    }
    
    return appliedParameters
  }
  
  var applied: [Filter] {
    all.filter(\.isOn)
  }
  
  // The  default filters to always apply, unless the user selects them, are .collection and .screencast
  // If the user makes a selection on ANY of them for the contentTypes group, only apply those
  // They can only select between .collection, .screencast
  var defaultFilters: [Filter] {
    Param
      .filters(for: [.contentTypes(types: [.collection, .screencast])])
      .map { Filter(groupType: .contentTypes, param: $0, isOn: true) }
  }
  
  var searchQuery: String? {
    didSet {
      searchStr = searchQuery ?? ""
      // Remove search filter from filters
      if let searchFilter = searchFilter {
        all.remove(searchFilter)
      }
      
      guard let query = searchQuery else {
        searchFilter = nil
        return
      }
      searchFilter = Filter(groupType: .search, param: Param.filter(for: .queryString(string: query)), isOn: !query.isEmpty)
      all.update(with: searchFilter!)
    }
  }
  
  private(set) var sortFilter: SortFilter
  private(set) var platforms: FilterGroup
  private(set) var categories: FilterGroup
  private(set) var contentTypes: FilterGroup
  private(set) var difficulties: FilterGroup
  private(set) var subscriptionPlans: FilterGroup
  private(set) var searchFilter: Filter?
  
  private var defaultParameters: [Parameter] {
    let sortParam = Param.sort(for: .releasedAt, descending: true)
    let contentFilters = defaultFilters
    
    var contentParams = FilterGroup(
      type: .contentTypes,
      filters: contentFilters
    ).filters.map(\.parameter)
    contentParams.append(sortParam)
    
    return contentParams
  }
  
  init() {
    self.sortFilter = SortFilter.newest
    self.platforms = FilterGroup(type: .platforms)
    self.categories = FilterGroup(type: .categories)
    
    let contentFilters = Param
      .filters(for: [.contentTypes(types: [.collection, .screencast])])
      .map { Filter(groupType: .contentTypes, param: $0, isOn: false ) }
    self.contentTypes = FilterGroup(type: .contentTypes, filters: contentFilters)
    
    let difficultyFilters = Param
      .filters(for: [.difficulties(difficulties: [.beginner, .intermediate, .advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }
    self.difficulties = FilterGroup(type: .difficulties, filters: difficultyFilters)
    
    let subscriptionPlanFilters = Param
      .filters(for: [.subscriptionPlans(plans: [.beginner, .professional])])
      .map { Filter(groupType: .subscriptionPlans, param: $0, isOn: false) }
    self.subscriptionPlans = FilterGroup(type: .subscriptionPlans, filters: subscriptionPlanFilters)
    
    // Check if there are filters in the settings manager
    let savedFilters = SettingsManager.current.filters
    if !savedFilters.isEmpty {
      // Validate loaded settings and put them in the right places
      self.platforms.updateFilters(from: savedFilters)
      self.categories.updateFilters(from: savedFilters)
      self.contentTypes.updateFilters(from: savedFilters)
      self.difficulties.updateFilters(from: savedFilters)
      self.subscriptionPlans.updateFilters(from: savedFilters)
    }
    
    let freshFilters =
      Set(platforms.filters)
        .union(contentTypes.filters)
        .union(difficulties.filters)
        .union(categories.filters)
        .union(subscriptionPlans.filters)
    self.all = freshFilters
    
    // Load the sort from the settings manager
    self.sortFilter = SettingsManager.current.sortFilter
  }
  
  func update(with filter: Filter) {
    if !filter.groupType.allowsMultipleValues && filter.isOn {
      // If you're only allowed one of this type, then let's turn the existing ones off
      let filtersToUpdate = all.filter { $0 != filter && $0.groupType == filter.groupType && $0.isOn }
      filtersToUpdate.forEach {
        $0.isOn.toggle()
      }
    }
    // Add the updated filter
    all.update(with: filter)
    commitUpdates()
  }
  
  func updatePlatformFilters(for domains: [Domain]) {
    let userFacingDomains = domains.filter { $0.level.userFacing }
    let domainTypes = userFacingDomains.map { (id: $0.id, name: $0.name, sortOrdinal: $0.ordinal) }
    let platformFilters = Param
      .filters(for: [.domainTypes(types: domainTypes)])
      .map { Filter(groupType: .platforms, param: $0, isOn: false ) }
    platforms.filters = platformFilters
    
    platformFilters.forEach { filter in
      all.insert(filter)
    }
    commitUpdates()
  }
  
  func updateCategoryFilters(for newCategories: [Category]) {
    let categoryTypes = newCategories.map { (id: $0.id, name: $0.name, sortOrdinal: $0.ordinal) }
    let categoryFilters = Param
      .filters(for: [.categoryTypes(types: categoryTypes)])
      .map { Filter(groupType: .categories, param: $0, isOn: false ) }
    categories.filters = categoryFilters
    
    categoryFilters.forEach { filter in
      all.insert(filter)
    }
    commitUpdates()
  }
  
  func removeAll() {
    applied.forEach {
      $0.isOn = false
      all.update(with: $0)
    }
    searchQuery = nil
    commitUpdates()
  }
  
  func changeSortFilter() {
    sortFilter = sortFilter.next
    SettingsManager.current.sortFilter = sortFilter
    objectWillChange.send()
  }
  
  func commitUpdates() {
    SettingsManager.current.filters = all
    objectWillChange.send()
  }
  
  // Returns the applied parameters array from an array of Filters, but applied the current sort and search filters as well
  // If there are no content filters, it adds the default ones.
  func appliedParamteresWithCurrentSortAndSearch(from filters: [Filter]) -> [Parameter] {
    var filterParameters = filters.map(\.parameter)
    let appliedContentFilters = filters.filter { $0.groupType == .contentTypes && $0.isOn }
    
    if appliedContentFilters.isEmpty {
      // Add default filters
      filterParameters.append(contentsOf: self.defaultFilters.map(\.parameter))
    }
    
    var appliedParameters = filterParameters + [sortFilter.parameter]
    
    if let searchFilter = searchFilter {
      appliedParameters.append(searchFilter.parameter)
    }
    
    return appliedParameters
  }
  
  func appliedParams(from filters: Filters) -> [Parameter] {
    var filterParameters = filters.applied.map(\.parameter)
    let appliedContentFilters = contentTypes.filters.filter(\.isOn)
    
    if appliedContentFilters.isEmpty {
      // Add default filters
      filterParameters.append(contentsOf: self.defaultFilters.map(\.parameter))
    }
    
    var appliedParameters = filterParameters + [sortFilter.parameter]
    
    if let searchFilter = searchFilter {
      appliedParameters.append(searchFilter.parameter)
    }
    
    return appliedParameters
  }
}
