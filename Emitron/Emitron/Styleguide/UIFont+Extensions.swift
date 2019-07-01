//
//  UIFont+Extensions.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
  static var uiLargeTitle: UIFont {
    return UIFont(name: "Bitter-Bold", size: 34.0)!
  }
  static var uiTitle1: UIFont {
    return UIFont(name: "Bitter-Bold", size: 28.0)!
  }
  static var uiTitle2: UIFont {
    return UIFont(name: "Bitter-Bold", size: 22.0)!
  }
  static var uiTitle3: UIFont {
    return UIFont(name: "Bitter-Bold", size: 20.0)!
  }
  static var uiTitle4: UIFont {
    return UIFont(name: "Bitter-Bold", size: 17.0)!
  }
  static var uiHeadline: UIFont {
    return UIFont(name: "Bitter-Regular", size: 17.0)!
  }
  static var uiBodyAppleDefault: UIFont {
    return UIFont.systemFont(ofSize: 17.0, weight: .regular)
  }
  static var uiButtonLabel: UIFont {
    return UIFont.systemFont(ofSize: 15.0, weight: .bold)
  }
  static var uiBodyCustom: UIFont {
    return UIFont.systemFont(ofSize: 15.0, weight: .regular)
  }
  static var uiLabel: UIFont {
    return UIFont.systemFont(ofSize: 14.0, weight: .semibold)
  }
  static var uiButtonLabelSmall: UIFont {
    return UIFont.systemFont(ofSize: 13.0, weight: .semibold)
  }
  static var uiFootnote: UIFont {
    return UIFont.systemFont(ofSize: 13.0, weight: .regular)
  }
  static var uiCaption: UIFont {
    return UIFont.systemFont(ofSize: 12.0, weight: .regular)
  }
}
