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

struct MainView: View {
  @EnvironmentObject var sessionController: SessionController
  @EnvironmentObject var dataManager: DataManager
  private let tabViewModel = TabViewModel()
  
  var body: some View {
    contentView
      .background(Color.backgroundColor)
      .overlay(MessageBarView(messageBus: MessageBus.current), alignment: .bottom)
  }
  
  private var contentView: AnyView {
    if !sessionController.isLoggedIn {
      return AnyView(LoginView())
    }
    
    if case .loaded = sessionController.permissionState {
      if sessionController.hasPermissionToUseApp {
        return tabBarView()
      } else {
        return AnyView(LogoutView())
      }
    }
    
    return AnyView(PermissionsLoadingView())
  }
  
  private func tabBarView() -> AnyView {
    let downloadsView = DownloadsView(
      contentScreen: .downloads(permitted: sessionController.user?.canDownload ?? false),
      downloadRepository: dataManager.downloadRepository
    )
    
    if case .online = sessionController.sessionState {
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
    
      return AnyView(
        TabNavView(libraryView: AnyView(libraryView),
                   myTutorialsView: AnyView(myTutorialsView),
                   downloadsView: AnyView(downloadsView))
          .environmentObject(tabViewModel)
      )
    } else if case .offline = sessionController.sessionState {
      return AnyView(
        TabNavView(libraryView: AnyView(OfflineView()),
                   myTutorialsView: AnyView(OfflineView()),
                   downloadsView: AnyView(downloadsView))
          .environmentObject(tabViewModel)
      )
    } else {
      return AnyView(LoadingView())
    }
  }
}
