// Copyright (c) 2021 Razeware LLC
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

import Foundation
import SwiftUI
import GRDB

@main
struct EmitronApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  typealias EmitronObjects = (
    persistenceStore: PersistenceStore,
    guardpost: Guardpost,
    sessionController: SessionController,
    settingsManager: SettingsManager,
    downloadService: DownloadService,
    dataManager: DataManager,
    messageBus: MessageBus
  )

  private var persistenceStore: PersistenceStore
  private var guardpost: Guardpost
  private var dataManager: DataManager
  private var sessionController: SessionController
  private var downloadService: DownloadService
  private var settingsManager: SettingsManager
  private var messageBus: MessageBus
  private var iconManager: IconManager
  
  init() {

    // setup objects
    let emitronObjects = EmitronApp.emitronObjects()
    persistenceStore = emitronObjects.persistenceStore
    guardpost = emitronObjects.guardpost
    dataManager = emitronObjects.dataManager
    sessionController = emitronObjects.sessionController
    downloadService = emitronObjects.downloadService
    settingsManager = emitronObjects.settingsManager
    messageBus = emitronObjects.messageBus
    iconManager = IconManager(messageBus: messageBus)

    // start service
    appDelegate.downloadService = downloadService
    downloadService.startProcessing()

    // configure ui
    customizeNavigationBar()
    customizeTableView()
    customizeControls()

    // additional setup
    setupAppReview()
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Rectangle()
          .fill(Color.background)
          .edgesIgnoringSafeArea(.all)
        MainView()
          .environmentObject(sessionController)
          .environmentObject(dataManager)
          .environmentObject(downloadService)
          .environmentObject(iconManager)
          .environmentObject(messageBus)
          .environmentObject(persistenceStore)
          .environmentObject(guardpost)
          .environmentObject(settingsManager)
      }
    }
  }

  static func emitronObjects() -> EmitronObjects {
    // Initialise the database
    // swiftlint:disable:next force_try
    let databaseURL = try! FileManager.default
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("emitron.sqlite")
    // swiftlint:disable:next force_try
    let databasePool = try! EmitronDatabase.openDatabase(atPath: databaseURL.path)
    let persistenceStore = PersistenceStore(db: databasePool)
    let guardpost = Guardpost(baseURL: "https://accounts.raywenderlich.com",
                              urlScheme: "com.razeware.emitron",
                              ssoSecret: Configuration.ssoSecret,
                              persistenceStore: persistenceStore)
    let sessionController = SessionController(guardpost: guardpost)
    let settingsManager = SettingsManager(userDefaults: .standard, userModelController: sessionController)
    let downloadService = DownloadService(persistenceStore: persistenceStore, userModelController: sessionController, settingsManager: settingsManager)
    let messageBus = MessageBus()
    let dataManager = DataManager(sessionController: sessionController, persistenceStore: persistenceStore, downloadService: downloadService, messageBus: messageBus, settingsManager: settingsManager)

    return EmitronObjects(
      persistenceStore: persistenceStore,
      guardpost: guardpost,
      sessionController: sessionController,
      settingsManager: settingsManager,
      downloadService: downloadService,
      dataManager: dataManager,
      messageBus: messageBus
    )
  }

  private mutating func startServices() {
    // guardpost
    guardpost = Guardpost(baseURL: "https://accounts.raywenderlich.com",
                          urlScheme: "com.razeware.emitron://",
                          ssoSecret: Configuration.ssoSecret,
                          persistenceStore: persistenceStore)

    // session controller
    sessionController = SessionController(guardpost: guardpost)

    // settings
    settingsManager = SettingsManager(
      userDefaults: .standard,
      userModelController: sessionController
    )

    // download service
    downloadService = DownloadService(
      persistenceStore: persistenceStore,
      userModelController: sessionController,
      settingsManager: settingsManager
    )
    appDelegate.downloadService = downloadService

    // data manager
    dataManager = DataManager(
      sessionController: sessionController,
      persistenceStore: persistenceStore,
      downloadService: downloadService,
      messageBus: messageBus,
      settingsManager: settingsManager
    )
    downloadService.startProcessing()
  }

  private func customizeNavigationBar() {
    UINavigationBar.appearance().backgroundColor = .backgroundColor

    UINavigationBar.appearance().largeTitleTextAttributes = [
      .foregroundColor: UIColor(named: "titleText")!,
      .font: UIFont.uiLargeTitle
    ]
    UINavigationBar.appearance().titleTextAttributes = [
      .foregroundColor: UIColor(named: "titleText")!,
      .font: UIFont.uiHeadline
    ]
  }

  private func customizeTableView() {
    UITableView.appearance().separatorColor = .clear
    UITableViewCell.appearance().backgroundColor = .backgroundColor
    UITableViewCell.appearance().selectionStyle = .none

    UITableView.appearance().backgroundColor = .backgroundColor
  }

  private func customizeControls() {
    UISwitch.appearance().onTintColor = .accent
  }

  private func setupAppReview() {
    if NSUbiquitousKeyValueStore.default.object(forKey: LookupKey.requestReview) == nil {
      NSUbiquitousKeyValueStore.default.set(Date().timeIntervalSince1970, forKey: LookupKey.requestReview)
    }
  }
}
