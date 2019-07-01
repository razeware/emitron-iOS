//
//  BlueView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct BlueView : View {
    var body: some View {
      
      ZStack {
        Color.paleBlue
         Text("I'm blue!").font(.uiLargeTitle)
      }
      
    }
}

#if DEBUG
struct BlueView_Previews : PreviewProvider {
    static var previews: some View {
        BlueView()
    }
}
#endif
