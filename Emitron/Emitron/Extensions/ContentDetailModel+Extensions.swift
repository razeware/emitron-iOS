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

import UIKit

extension ContentDetailsModel {
  var releasedAtDateTimeString: String {
    var start = releasedAt.cardString
    if Calendar.current.isDate(Date(), inSameDayAs: releasedAt) {
      start = Constants.today
    }
    
    return "\(start) • \(contentType.displayString) (\(duration.timeFromSeconds))"
  }
  
  var cardViewSubtitle: String {
    guard let domainData = DataManager.current?.domainsMC.data else {
      return ""
    }
    
    let contentDomains = domainData.filter { domains.contains($0) }
    let subtitle = contentDomains.count > 1 ? "Multi-platform" : contentDomains.first?.name ?? ""
    
    return subtitle
  }
  
  var progress: CGFloat {
    var progress: CGFloat = 0
    if let progression = progression {
      progress = progression.finished ? 1 : CGFloat(progression.percentComplete / 100)
    }
    return progress
  }
}

extension ContentSummaryModel {
  var releasedAtDateTimeString: String {
    var start = releasedAt.cardString
    if Calendar.current.isDate(Date(), inSameDayAs: releasedAt) {
      start = Constants.today
    }
    
    return "\(start) • \(contentType.displayString) (\(duration.timeFromSeconds))"
  }
}
