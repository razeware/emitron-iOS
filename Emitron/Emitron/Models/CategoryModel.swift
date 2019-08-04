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
import SwiftyJSON

class CategoryModel {

  // MARK: - Properties
  private(set) var id: Int = 0
  private(set) var name: String = ""
  private(set) var uri: String = ""
  private(set) var ordinal: Int = 0 //  Sort order for displaying categories

  // MARK: - Initializers
  init?(_ jsonResource: JSONAPIResource,
        metadata: [String: Any]?) {
    self.id = jsonResource.id
    self.name = jsonResource["name"] as? String ?? ""
    self.uri = jsonResource["uri"] as? String ??  ""
    self.ordinal = jsonResource["ordinal"] as? Int ?? 0
  }

  /// Convenience initializer to transform core data **CategoryEntity** into a **Category** model
  ///
  /// - parameters:
  ///   - category: core data entity to transform into category model
  init(_ category: Category) {
    self.name = category.name
    self.uri = category.uri
    self.ordinal = category.ordinal.intValue
  }
}

extension CategoryModel {
  static var test: [CategoryModel] {
    do {
      let fileURL = Bundle.main.url(forResource: "CategoriesModelTest", withExtension: "json")
      let data = try Data(contentsOf: fileURL!)
      let json = try JSON(data: data)
    
      let document = JSONAPIDocument(json)
      let categories = document.data.compactMap { CategoryModel($0, metadata: nil) }
      return categories
    } catch {
      return []
    }
  }
}
