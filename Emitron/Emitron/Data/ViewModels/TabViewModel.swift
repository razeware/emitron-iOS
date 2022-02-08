// Copyright (c) 2022 Razeware LLC
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
import SwiftUI

final class TabViewModel: ObservableObject {
  enum MainTab {
    case library
    case downloads
    case myTutorials
    case settings
  }

  /// An ID that tells a scroll view proxy what view to scroll to when tapping an already-selected tab.
  struct ScrollToTopID {
    let mainTab: MainTab
    let detail: Bool
  }

  @Published var selectedTab: MainTab = .library

  var showingDetailView = Dictionary(
    uniqueKeysWithValues: zip(MainTab.allCases, AnyIterator { false })
  )
}

// MARK: - CaseIterable
extension TabViewModel.MainTab: CaseIterable { }

// MARK: - Environment
extension TabViewModel.MainTab: EnvironmentKey {
  static var defaultValue: Self { .library }
}

extension EnvironmentValues {
  var mainTab: TabViewModel.MainTab {
    get { self[TabViewModel.MainTab.self] }
    set { self[TabViewModel.MainTab.self] = newValue }
  }
}

// MARK: - Hashable
extension TabViewModel.ScrollToTopID: Hashable { }
