//
//  TabbedView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct TabBar: View {
    var body: some View {
      TabbedView {
        BlueView()
          .tabItemLabel(Text("Blue"))
          .tag(0)
        OrangeView()
          .tabItemLabel(Text("Orange"))
          .tag(1)
      }
    }
}

#if DEBUG
struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}
#endif
