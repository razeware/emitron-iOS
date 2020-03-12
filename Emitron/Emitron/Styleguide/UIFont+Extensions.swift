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

import UIKit

extension UIFont {
  static var uiLargeTitle: UIFont {
    UIFont(name: "Bitter-Bold", size: 34.0)!
  }
  static var uiTitle1: UIFont {
    UIFont(name: "Bitter-Bold", size: 28.0)!
  }
  static var uiTitle2: UIFont {
    UIFont(name: "Bitter-Bold", size: 22.0)!
  }
  static var uiTitle3: UIFont {
    UIFont(name: "Bitter-Bold", size: 20.0)!
  }
  static var uiTitle4: UIFont {
    UIFont(name: "Bitter-Bold", size: 17.0)!
  }
  static var uiHeadline: UIFont {
    UIFont(name: "Bitter-Regular", size: 17.0)!
  }
  
  static var uiNumberBox: UIFont {
    UIFont(name: "Bitter-Bold", size: 13.0)!
  }
  
  static var uiBodyAppleDefault: UIFont {
    UIFont.systemFont(ofSize: 17.0, weight: .regular)
  }
  static var uiButtonLabel: UIFont {
    UIFont.systemFont(ofSize: 15.0, weight: .bold)
  }
  static var uiBodyCustom: UIFont {
    UIFont.systemFont(ofSize: 15.0, weight: .regular)
  }
  static var uiLabel: UIFont {
    UIFont.systemFont(ofSize: 14.0, weight: .semibold)
  }
  static var uiButtonLabelSmall: UIFont {
    UIFont.systemFont(ofSize: 13.0, weight: .semibold)
  }
  static var uiFootnote: UIFont {
    UIFont.systemFont(ofSize: 13.0, weight: .regular)
  }
  static var uiCaption: UIFont {
    UIFont.systemFont(ofSize: 12.0, weight: .regular)
  }
  static var uiUppercase: UIFont {
    UIFont.systemFont(ofSize: 11.0, weight: .medium)
  }
}
