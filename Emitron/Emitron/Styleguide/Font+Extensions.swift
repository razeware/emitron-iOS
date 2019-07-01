//
//  Font+Extensions.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

extension Font {
  static var uiLargeTitle: Font {
    return Font.custom("Bitter-Bold", size: 34.0)
  }
  static var uiTitle1: Font {
    return Font.custom("Bitter-Bold", size: 28.0)
  }
  static var uiTitle2: Font {
    return Font.custom("Bitter-Bold", size: 22.0)
  }
  static var uiTitle3: Font {
    return Font.custom("Bitter-Bold", size: 20.0)
  }
  static var uiTitle4: Font {
    return Font.custom("Bitter-Bold", size: 17.0)
  }
  static var uiHeadline: Font {
    return Font.custom("Bitter-Regular", size: 17.0)
  }
  
  static var uiBodyAppleDefault: Font {
    return Font.body
  }
  
  // Can't have bold Font's
  static var uiButtonLabel: Font {
    return Font.system(size: 15.0).bold()
  }
  static var uiBodyCustom: Font {
    return Font.system(size: 15.0)
  }
  static var uiLabel: Font {
    return Font.system(size: 14.0).weight(.semibold)
  }
  static var uiButtonLabelSmall: Font {
    return Font.system(size: 13.0).weight(.semibold)
  }
  static var uiFootnote: Font {
    return Font.footnote
  }
  static var uiCaption: Font {
    return Font.system(size: 12.0)
  }
}

