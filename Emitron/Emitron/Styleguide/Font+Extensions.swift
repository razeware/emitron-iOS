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

import SwiftUI

extension Font {
  static var uiLargeTitle: Font {
    .custom("Bitter-Bold", size: 34.0, relativeTo: .largeTitle)
  }
  static var uiTitle1: Font {
    .custom("Bitter-Bold", size: 28.0, relativeTo: .title)
  }
  static var uiTitle2: Font {
    .custom("Bitter-Bold", size: 23.0, relativeTo: .title2)
  }
  static var uiTitle3: Font {
    .custom("Bitter-Bold", size: 20.0, relativeTo: .title3)
  }
  static var uiTitle4: Font {
    .custom("Bitter-Bold", size: 19.0, relativeTo: .title3)
  }
  static var uiTitle5: Font {
    .custom("Bitter-Regular", size: 17.0, relativeTo: .body)
  }
  static var uiHeadline: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 18.0)).weight(.semibold)
  }
  
  static var uiNumberBox: Font {
    .custom("Bitter-Bold", size: 13.0, relativeTo: .footnote)
  }

  static var uiBodyAppleDefault: Font { .body }

  // Can't have bold Font's
  static var uiButtonLabelLarge: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 17.0)).bold()
  }
  static var uiButtonLabelMedium: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 15)).weight(.bold)
  }
  static var uiButtonLabelSmall: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 13.0)).weight(.semibold)
  }
  static var uiBodyCustom: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 15.0))
  }
  static var uiLabelBold: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 16.0)).weight(.semibold)
  }
  static var uiLabel: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 16.0))
  }
  static var uiFootnote: Font { .footnote }
  static var uiCaption: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 14.0))
  }
  static var uiUppercase: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 12.0)).weight(.semibold)
  }
  static var uiUppercaseTag: Font {
    .system(size: UIFontMetrics.default.scaledValue(for: 10.0)).weight(.semibold)
  }
}
