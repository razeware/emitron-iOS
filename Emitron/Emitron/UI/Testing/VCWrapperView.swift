//
//  VCWrapperView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct ViewControllerWrapper: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = ViewController
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ViewControllerWrapper>) -> ViewControllerWrapper.UIViewControllerType {
    return ViewController()
  }
  
  func updateUIViewController(_ uiViewController: ViewControllerWrapper.UIViewControllerType, context: UIViewControllerRepresentableContext<ViewControllerWrapper>) {
    //
  }
}

struct VCWrapperView : View {
  var body: some View {
    ViewControllerWrapper()
  }
}

#if DEBUG
struct VCWrapperView_Previews : PreviewProvider {
  static var previews: some View {
    VCWrapperView()
  }
}
#endif
