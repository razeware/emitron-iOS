// Copyright (c) 2020 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Combine

class IconManager: ObservableObject {
  private(set) var icons = [Icon]()
  @Published private(set) var currentIcon: Icon?
  
  init() {
    populateIcons()
      
    let currentIconName = UIApplication.shared.alternateIconName
    currentIcon = icons.first { $0.name == currentIconName }!
  }
  
  func set(icon: Icon) {
    UIApplication.shared.setAlternateIconName(icon.name) { error in
      DispatchQueue.main.async {
        if let error = error {
          Failure
            .appIcon(from: String(describing: type(of: self)), reason: error.localizedDescription)
            .log()
          MessageBus.current.post(message: Message(level: .error, message: Constants.appIconUpdateProblem))
        } else {
          self.currentIcon = icon
          MessageBus.current.post(message: Message(level: .success, message: Constants.appIconUpdatedSuccessfully))
        }
      }
    }
  }

  private func populateIcons() {
    guard let plistIcons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any] else { return }
    
    var iconList = [Icon]()
    
    if let primaryIcon = plistIcons["CFBundlePrimaryIcon"] as? [String: Any],
      let files = primaryIcon["CFBundleIconFiles"] as? [String],
      let fileName = files.first {
      iconList.append(Icon(name: nil, imageName: fileName, ordinal: 0))
    }
    
    if let alternateIcons = plistIcons["CFBundleAlternateIcons"] as? [String: Any] {
         
      iconList += alternateIcons.compactMap { key, value in
        guard let alternateIcon = value as? [String: Any],
          let files = alternateIcon["CFBundleIconFiles"] as? [String],
          let fileName = files.first,
          let ordinal = alternateIcon["ordinal"] as? Int else { return nil }
        
        return Icon(name: key, imageName: fileName, ordinal: ordinal)
      }
      .sorted()
    }
    
    icons = iconList
  }
}
