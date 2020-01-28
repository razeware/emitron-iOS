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

protocol Refreshable {
  var refreshableUserDefaultsKey: String { get }
  var refreshableCheckTimeSpan: RefreshableTimeSpan { get }
  var shouldRefresh: Bool { get }

  // Every class that conforms to the protocol has to call this function after the "refreshable" action has been completed to store the date it was last updated on
  func saveOrReplaceRefreshableUpdateDate()
}

extension Refreshable {
  
  var shouldRefresh: Bool {
    if let lastUpdateDate = UserDefaults.standard.object(forKey: self.refreshableUserDefaultsKey) as? Date {
      if lastUpdateDate > self.refreshableCheckTimeSpan.date {
        Event
          .refresh(from: String(describing: type(of: self)), action: "Last Updated: \(lastUpdateDate). No refresh required.")
          .log()
        return false
      } else {
        Event
          .refresh(from: String(describing: type(of: self)), action: "Last Updated: \(lastUpdateDate). Refresh is required.")
          .log()
        return true
      }
    }
    Event
      .refresh(from: String(describing: type(of: self)), action: "Last Updated: UNKNOWN. Refresh is required.")
      .log()
    return true
  }
  
  func saveOrReplaceRefreshableUpdateDate() {
    UserDefaults.standard.set(Date(),
                              forKey: self.refreshableUserDefaultsKey)
  }
}

enum RefreshableTimeSpan: Int {
  // These are day values
  case long = 30
  case short = 1
  
  var date: Date {
    Date().dateByAddingNumberOfDays(-self.rawValue)
  }
}
