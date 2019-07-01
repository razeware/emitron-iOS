//
//  TabBarView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct TabBarView : View {
    var body: some View {
      
      TabbedView {
        
        OrangeView()
          .tabItemLabel(Text("Orange"))
          .tag(0)
        
        BlueView()
          .tabItemLabel(Text("Blue"))
          .tag(1)
      }
    }
}

#if DEBUG
struct TabBarView_Previews : PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
#endif
