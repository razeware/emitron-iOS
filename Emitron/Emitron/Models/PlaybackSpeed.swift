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

enum PlaybackSpeed: Int, CaseIterable, SettingsSelectable {
  case half
  case standard
  case onePointFive
  case double
  
  static func fromDisplay(_ value: String) -> PlaybackSpeed? {
    allCases.first { $0.display == value }
  }
  
  var rate: Float {
    switch self {
    case .half:
      return 0.5
    case .standard:
      return 1.0
    case .onePointFive:
      return 1.5
    case .double:
      return 2.0
    }
  }
  
  var display: String {
    switch self {
    case .half:
      return "0.5x"
    case .standard:
      return "1.0x"
    case .onePointFive:
      return "1.5x"
    case .double:
      return "2.0x"
    }
  }
  
  static var selectableCases: [PlaybackSpeed] {
    allCases
  }
}
