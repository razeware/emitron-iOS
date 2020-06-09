// Copyright (c) 2019 Razeware LLC
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
import AVFoundation
import GRDB

// swiftlint:disable strict_fileprivate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  private var persistenceStore: PersistenceStore!
  private var guardpost: Guardpost!
  fileprivate var dataManager: DataManager!
  fileprivate var sessionController: SessionController!
  fileprivate var downloadService: DownloadService!
  fileprivate var messageBus = MessageBus()
  fileprivate var settingsManager: SettingsManager!
  fileprivate var iconManager = IconManager()

  func applicationDidFinishLaunching(_ application: UIApplication) {
    // Override point for customization after application launch.
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(AVAudioSession.Category.playback)
    } catch {
      print("Setting category to AVAudioSessionCategoryPlayback failed.")
    }
    
    // Initialise the database
    // swiftlint:disable:next force_try
    let dbPool = try! setupDatabase(application)
    persistenceStore = PersistenceStore(db: dbPool)
    guardpost = Guardpost(baseUrl: "https://accounts.raywenderlich.com",
                          urlScheme: "com.razeware.emitron://",
                          ssoSecret: Configuration.ssoSecret,
                          persistenceStore: persistenceStore)
    
    sessionController = SessionController(guardpost: guardpost)
    settingsManager = SettingsManager(
      userDefaults: .standard,
      userModelController: sessionController
    )
    downloadService = DownloadService(
      persistenceStore: persistenceStore,
      userModelController: sessionController
    )
    dataManager = DataManager(
      sessionController: sessionController,
      persistenceStore: persistenceStore,
      downloadService: downloadService
    )
    downloadService.startProcessing()    
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
  
  // For dealing with downloading of videos in the background
  func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    assert(identifier == DownloadProcessor.sessionIdentifier, "Unknown Background URLSession. Unable to handle these events.")
    
    downloadService.backgroundSessionCompletionHandler = completionHandler
  }
  
  private func setupDatabase(_ application: UIApplication) throws -> DatabasePool {
    let databaseURL = try FileManager.default
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("emitron.sqlite")
    let dbPool = try EmitronDatabase.openDatabase(atPath: databaseURL.path)
    
    // Be a nice iOS citizen, and don't consume too much memory
    // See https://github.com/groue/GRDB.swift/blob/master/README.md#memory-management
    dbPool.setupMemoryManagement(in: application)
    
    return dbPool
  }
}

// MARK: - Making some delightful global-access points. Classy.
extension SessionController {
  static var current: SessionController {
    (UIApplication.shared.delegate as! AppDelegate).sessionController
  }
}

extension DataManager {
  static var current: DataManager {
    (UIApplication.shared.delegate as! AppDelegate).dataManager
  }
}

extension DownloadService {
  static var current: DownloadService {
    (UIApplication.shared.delegate as! AppDelegate).downloadService
  }
}

extension MessageBus {
  static var current: MessageBus {
    (UIApplication.shared.delegate as! AppDelegate).messageBus
  }
}

extension SettingsManager {
  static var current: SettingsManager {
    (UIApplication.shared.delegate as! AppDelegate).settingsManager
  }
}

extension IconManager {
  static var current: IconManager {
    (UIApplication.shared.delegate as! AppDelegate).iconManager
  }
}
