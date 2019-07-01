//
//  ViewController.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import UIKit
import Crashlytics
import Fabric

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view, typically from a nib.
    
    let button = UIButton(type: .roundedRect)
    button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
    button.setTitle("Crash", for: [])
    button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), for: .touchUpInside)
    view.addSubview(button)
    
    Fabric.sharedSDK().debug = true
  }
  
  @IBAction func crashButtonTapped(_ sender: AnyObject) {
    Crashlytics.sharedInstance().crash()
  }
}
