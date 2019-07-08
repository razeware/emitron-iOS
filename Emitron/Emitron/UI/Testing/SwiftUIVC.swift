//
//  SwiftUI+UIKit.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/4/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI
import UIKit


struct VC: UIViewControllerRepresentable {
  var controllers: [UIViewController]
  
  func makeUIViewController(context: Context) -> UIViewController {
    return ViewController()
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // Nothing to update here really.
  }
}
