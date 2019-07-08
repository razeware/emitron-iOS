//
//  SwiftUIView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/4/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct SwiftUIView<Page: View> : View {
  var viewControllers: [UIHostingController<Page>]
  
  init(_ views: [Page]) {
    self.viewControllers = views.map { UIHostingController(rootView: $0) }
  }
    var body: some View {
      VC(controllers: [ViewController()])
    }
}

#if DEBUG
struct SwiftUIView_Previews : PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
#endif
