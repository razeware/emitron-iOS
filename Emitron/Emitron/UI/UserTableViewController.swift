/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

class UserTableViewController: UITableViewController {
  var user: User? {
    didSet {
      updateUI()
    }
  }
  
  var guardpost: Guardpost?
  
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var emailLabel: UILabel!
  @IBOutlet weak var externalIdLabel: UILabel!
  @IBOutlet weak var tokenLabel: UILabel!
  
  @IBAction func handleLogoutTapped(_ sender: Any) {
    guardpost?.logout()
    self.dismiss(animated: true, completion: .none)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    updateUI()
  }
  
  private func updateUI() {
    guard let user = user else { return }
    
    let downloadTask = URLSession.shared.downloadTask(with: user.avatarUrl) { (location, _, _) in
      guard let location = location,
        let image = try? UIImage(data: Data(contentsOf: location)) else { return }
      DispatchQueue.main.async {
        self.avatarImageView?.image = image
      }
    }
    
    downloadTask.resume()
    
    usernameLabel?.text = user.username
    nameLabel?.text = user.name
    emailLabel?.text = user.email
    externalIdLabel?.text = user.externalId
    tokenLabel?.text = user.token
  }
}
