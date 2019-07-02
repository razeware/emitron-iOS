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
                            ssoSecret: "<SSO_SECRET>")
  
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
        self.displayError(error.localizedDescription)
      case .success(let user):
        self.performRequest(user)
//        self.displayUser(user)
      }
    }
  }
  
  private func performRequest(_ user: User) {
    
    let client = RWAPI(authToken: "\(user.token)")
    let bookmarkService =  BookmarksService(client: client)
    bookmarkService.allBookmarks { [weak self] result in
      guard let `self` = self else { return }
      
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let bookmarks):
        print(bookmarks.first!.bookmarkId)
      }
    }
  }
  
  private func displayError(_ error: String?) {
    print(error)
  }
  
//  private func displayUser(_ user: User) {
//    let storyboard = UIStoryboard(name: "Main", bundle: .none)
//    if let userVC = storyboard.instantiateViewController(withIdentifier: "userVC") as? UserTableViewController {
//      userVC.user = user
//      userVC.guardpost = guardpost
//
//      self.present(userVC, animated: true, completion: .none)
//    }
//  }
  
  @IBAction func crashButtonTapped(_ sender: AnyObject) {
    Crashlytics.sharedInstance().crash()
  }
}

extension ViewController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.keyWindow ?? UIWindow()
  }
}

