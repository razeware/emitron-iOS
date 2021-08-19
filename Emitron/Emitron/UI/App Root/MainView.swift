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

import SwiftUI
import StoreKit

struct MainView: View {
  @EnvironmentObject private var sessionController: SessionController
  @EnvironmentObject private var dataManager: DataManager
  @EnvironmentObject private var messageBus: MessageBus
  @EnvironmentObject private var settingsManager: SettingsManager

  private let tabViewModel = TabViewModel()
  private let notification = NotificationCenter.default.publisher(for: .requestReview)

  var body: some View {
    ZStack {
      contentView
        .background(Color.backgroundColor)
        .overlay(MessageBarView(messageBus: messageBus), alignment: .bottom)
        .onReceive(notification) { _ in
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            makeReviewRequest()
          }
        }
    }
  }

  private func makeReviewRequest() {
    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    }
  }
}

// MARK: - private
private extension MainView {
  @ViewBuilder var contentView: some View {
    if !sessionController.isLoggedIn {
      LoginView()
    } else {
      switch sessionController.permissionState {
      case .loaded:
        if sessionController.hasPermissionToUseApp {
          tabBarView
        } else {
          LogoutView()
        }
      case .notLoaded, .loading:
        PermissionsLoadingView()
      case .error:
        ErrorView(
          titleText: "An error occurred",
          bodyText: """
            We’re sorry! We failed to fetch the correct permissions and now you’re seeing this screen. \
            To fix this problem, click the button below.
            """,
          buttonTitle: "Back to login screen",
          buttonAction: sessionController.logout
        )
      }
    }
  }
  
  @ViewBuilder var tabBarView: some View {
    let downloadsView = DownloadsView(
      contentScreen: .downloads(permitted: sessionController.user?.canDownload ?? false),
      downloadRepository: dataManager.downloadRepository
    )
    let settingsView = SettingsView(settingsManager: settingsManager)

    switch sessionController.sessionState {
    case .online :
      let libraryView = LibraryView(
        filters: dataManager.filters,
        libraryRepository: dataManager.libraryRepository
      )
      
      let myTutorialsView = MyTutorialView(
        state: .inProgress,
        inProgressRepository: dataManager.inProgressRepository,
        completedRepository: dataManager.completedRepository,
        bookmarkRepository: dataManager.bookmarkRepository,
        domainRepository: dataManager.domainRepository
      )

      TabNavView(
        libraryView: libraryView,
        myTutorialsView: myTutorialsView,
        downloadsView: downloadsView,
        settingsView: settingsView
      )
      .environmentObject(tabViewModel)
    case .offline:
      TabNavView(libraryView: OfflineView(),
                 myTutorialsView: OfflineView(),
                 downloadsView: downloadsView,
                 settingsView: settingsView)
        .environmentObject(tabViewModel)
    case .unknown:
      LoadingView()
    }
  }
}
