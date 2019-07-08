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
import AuthenticationServices
import CryptoKit

class ViewController: UIViewController {

  let guardpost = Guardpost(baseUrl: "https://accounts.raywenderlich.com",
                            urlScheme: "com.razeware.emitron://",
                            ssoSecret: "3c62ef6384b3becef0261f4b612278d45e46618127194cfc380497997a7150e8083afe8e950f54801adfc25d9af7f949b01656ea0543943a6145ffc1ae013115")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view, typically from a nib.
    
    let button = UIButton(type: .roundedRect)
    button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
    button.setTitle("Login", for: [])
    button.addTarget(self, action: #selector(login), for: .touchUpInside)
    view.addSubview(button)
    
    if let user = guardpost.currentUser {
      performRequest(user)
    }
  }
  
  @objc func login() {
    guardpost.presentationContextDelegate = self
    
    guardpost.login { (result) in
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let user):
        self.performRequest(user)
      }
    }
  }
  
  private func performRequest(_ user: User) {
        
    let client = RWAPI(authToken: "\(user.token)")
    //let service =  ProgressionsService(client: client)
    let contentsService = ContentsService(client: client)
    
    let filterParams = Param.filter(by: [.contentTypes(types: [.collection])])
    let sortParam = Param.sort(by: .releasedAt, descending: true)
    let completionParam = ParameterKey.completionStatus(status: .completed).param
    let pageSizeParam = ParameterKey.pageSize(size: 21).param
    let params = filterParams + [sortParam] + [pageSizeParam]
    
//    service.progressions(parameters: params) { result in
//      switch result {
//      case .failure(let error):
//        print(error.localizedDescription)
//      case .success(let progressions):
//        print(progressions.count)
//      }
//    }
    contentsService.allContents(parameters: params) { result in
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let contents):
        print(contents.count)
      }
    }
  }
  
  @IBAction func crashButtonTapped(_ sender: AnyObject) {
    Crashlytics.sharedInstance().crash()
  }
}

extension ViewController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.windows.first!
  }
}

