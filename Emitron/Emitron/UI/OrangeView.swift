//
//  OrangeView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct OrangeView : View {
    var body: some View {
      
      ZStack {
        Color.copper
        Text("I'm orange!").font(.uiLargeTitle)
      }
      
    }
}

#if DEBUG
struct OrangeView_Previews : PreviewProvider {
    static var previews: some View {
        OrangeView()
    }
}
#endif
