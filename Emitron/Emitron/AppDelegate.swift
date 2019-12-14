/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.


import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  private (set) var persistenceStore = PersistenceStore()
  private (set) var guardpost: Guardpost?
  var dataManager: DataManager?
  private (set) var userModelController: UserMC!
  private var downloadService: DownloadService!
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSession.Category.playback)
    } catch {
        print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
    
    // TODO: When you're logged out datamanager will be nil in this current setup
    self.guardpost = Guardpost(baseUrl: "https://accounts.raywenderlich.com",
                               urlScheme: "com.razeware.emitron://",
                               ssoSecret: Configuration.ssoSecret,
                               persistenceStore: persistenceStore)
    
    guard let guardpost = guardpost else { return true }
    userModelController = UserMC(guardpost: guardpost)
    downloadService = DownloadService(
      coreDataStack: persistenceStore.coreDataStack,
      userModelController: userModelController
    )
    
    guard let user = guardpost.currentUser else { return true }
    self.dataManager = DataManager(user: user,
                                   persistenceStore: persistenceStore)
    
    return true
  }
  
  // MARK: UISceneSession Lifecycle
  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration",
                                sessionRole: connectingSceneSession.role)
  }
  
  func application(_ application: UIApplication,
                   didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
  
  // handle orientation for the device
  func application (_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
      guard let vc = (window?.rootViewController?.presentedViewController) else {
          return .portrait
      }
      if (vc.isKind(of: NSClassFromString("AVFullScreenViewController")!)){
          return .allButUpsideDown
      } else {
          return .portrait
      }
  }
  
  // For dealing with downloading of videos in the background
  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    assert(identifier == DownloadProcessor.sessionIdentifier, "Unknown Background URLSession. Unable to handle these events.")
    
    downloadService.backgroundSessionCompletionHandler = completionHandler
  }
}


// MARK:- Making the UserModelController a hacky singleton
extension UserMC {
  static var current: UserMC {
    (UIApplication.shared.delegate as! AppDelegate).userModelController
  }
}
