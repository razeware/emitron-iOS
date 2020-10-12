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

import typealias Foundation.TimeInterval

extension TimeInterval {
  static let oneMinute: TimeInterval = 60
  static let oneHour: TimeInterval = 3600
  static let oneDay: TimeInterval = 86400
}

extension Int {
  var minutes: TimeInterval {
    .oneMinute * Double(self)
  }
  
  var hours: TimeInterval {
    .oneHour * Double(self)
  }
  
  var days: TimeInterval {
    .oneDay * Double(self)
  }
  
  var minutesFromSeconds: Double {
    Double(self) / TimeInterval.oneMinute
  }
  
  var timeFromSeconds: String {
    let hours = minutesFromSeconds / 60
    let minutes = minutesFromSeconds.truncatingRemainder(dividingBy: 60)
    
    let intHours = Int(hours)
    let intMinutes = Int(minutes)
    
    var timeString = ""
    
    switch (intHours, intMinutes) {
      
    case (0, 0):
      break
    case (0, 1):
      timeString = "\(intMinutes) min"
    case (0, _):
      timeString = "\(intMinutes) mins"
    case (1, 0):
      timeString = "\(intHours) hr"
    case (_, 0):
      timeString = "\(intHours) hrs"
    case (1, 1):
      timeString = "\(intHours) hr, \(intMinutes) min"
    case (1, _):
      timeString = "\(intHours) hr, \(intMinutes) mins"
    case (_, 1):
      timeString = "\(intHours) hrs, \(intMinutes) min"
    case (_, _):
      timeString = "\(intHours) hrs, \(intMinutes) mins"
    }
    
    return timeString
  }
  
  var minuteSecondTimeFromSeconds: String {
    let minutes = Int(minutesFromSeconds)
    let seconds = self - minutes * 60
    
    return "\(minutes):\(String(format: "%02d", seconds))"
  }
}
