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

struct FilterGroup: Hashable {
  var type: FilterGroupType
  var filters: [Filter]
  var numApplied: Int {
    filters.filter(\.isOn).count
  }
  
  init(type: FilterGroupType, filters: [Filter] = []) {
    self.type = type
    self.filters = filters
  }
  
  /// Update the filters in this group from a set of filters loaded from the data store
  /// - Parameter savedFilters: A Set of filters, often stored in UserSettings
  func updateFilters(from savedFilters: Set<Filter>) {
    // We only care about filters that are from the same group
    let relevantFilters = savedFilters.filter { $0.groupType == type }
    // Let's go through those saved filters and load the relevant data
    relevantFilters.forEach { filter in
      // If we don't have a stored filter that matched the update, ignore it
      guard let storedFilter = self.filters.first(where: { $0 == filter }) else { return }
      // The only attribute we care about is whether or not the filter is currently applied
      storedFilter.isOn = filter.isOn
    }
  }
}

enum FilterGroupType: String, Hashable, CaseIterable, Codable {
  case platforms = "Platforms"
  case categories = "Categories"
  case subscriptionPlans = "Membership Level"
  case contentTypes = "Content Type"
  case difficulties = "Difficulty"
  case search = "Search"
  case none = "" // For filters whose values aren't an array, for example the search query
  
  var name: String {
    self.rawValue
  }
  
  var allowsMultipleValues: Bool {
    switch self {
    case .subscriptionPlans, .search, .none:
      return false
    default:
      return true
    }
  }
}
