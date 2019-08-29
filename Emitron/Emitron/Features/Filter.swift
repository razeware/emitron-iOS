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

class Filter: Hashable, Codable {
  
  static func == (lhs: Filter, rhs: Filter) -> Bool {
    return lhs.filterName == rhs.filterName
  }
  
  // In order for Set equality operations to work on a Class, we have to make sure that the reference hashes are the same between filters,
  // so we implement our own hashing function
  func hash(into hasher: inout Hasher) {
      hasher.combine(filterName)
  }
    
  // MARK: - Properties
  var parameter: Parameter
  var isOn: Bool
  
  var groupType: FilterGroupType
  
  var groupName: String {
    return groupType.name
  }
  
  var filterName: String {
    return parameter.displayName
  }
  
  // MARK: - Initializers
  init(groupType: FilterGroupType, param: Parameter, isOn: Bool = false) {
    self.groupType = groupType
    self.parameter = param
    self.isOn = isOn
  }
}

// For testing
extension Filter {
  static var testFilter: Filter {
    return Filter(groupType: .contentTypes, param: Parameter(key: "", value: "", displayName: ""))
  }
}
