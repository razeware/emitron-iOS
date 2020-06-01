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

import AuthenticationServices

import Combine
import Network

// This protocol is added to aid testing (of DownloadService). It is not
// currently necesarily complete. It should probably be revisited,
// and rethought at a later stage. I'll put // TODO: here so that we might
// find it again.
protocol UserModelController {
  var objectDidChange: ObservableObjectPublisher { get }
  var user: User? { get }
  var client: RWAPI { get }
}

// Conforming to NSObject, so that we can conform to ASWebAuthenticationPresentationContextProviding
class SessionController: NSObject, UserModelController, ObservablePrePostFactoObject, Refreshable {
  // MARK: Refreshable
  var refreshableCheckTimeSpan: RefreshableTimeSpan = .short
  
  private var subscriptions = Set<AnyCancellable>()

  // Managing the state of the current session
  private(set) var sessionState: SessionState = .unknown
  @Published private(set) var userState: UserState = .notLoggedIn
  @Published private(set) var permissionState: PermissionState = .notLoaded
  
  @PublishedPrePostFacto var user: User? {
    didSet {
      if let user = user {
        userState = .loggedIn
        if user.permissions == nil {
          permissionState = .notLoaded
          fetchPermissionsIfNeeded()
        } else {
          permissionState = .loaded(lastRefreshedDate)
        }
      } else {
        userState = .notLoggedIn
        permissionState = .notLoaded
      }
    }
  }
  let objectDidChange = ObservableObjectPublisher()
  
  private let guardpost: Guardpost
  private let connectionMonitor = NWPathMonitor()
  private(set) var client: RWAPI
  private(set) var permissionsService: PermissionsService
  
  var isLoggedIn: Bool {
    userState == .loggedIn
  }
  
  var hasPermissions: Bool {
    if case .loaded = permissionState {
      return true
    }
    return false
  }
  
  var hasPermissionToUseApp: Bool {
    user?.hasPermissionToUseApp ?? false
  }
  
  var hasCurrentDownloadPermissions: Bool {
    guard user?.canDownload == true else { return false }
    
    if case .loaded(let date) = permissionState,
      let permissionsLastConfirmedDate = date,
      Date().timeIntervalSince(permissionsLastConfirmedDate) < Constants.videoPlaybackOfflinePermissionsCheckPeriod {
      return true
    }
    return false
  }
  
  // MARK: - Initializers
  init(guardpost: Guardpost) {
    dispatchPrecondition(condition: .onQueue(.main))
    
    self.guardpost = guardpost

    let user = User.backdoor ?? guardpost.currentUser
    self.user = user
    self.client = RWAPI(authToken: user?.token ?? "")
    self.permissionsService = PermissionsService(client: self.client)
    super.init()
    
    prepareSubscriptions()
  }
  
  // MARK: - Internal
  func login() {
    guard userState != .loggingIn else { return }
    
    userState = .loggingIn
    guardpost.presentationContextDelegate = self
    
    if isLoggedIn {
      if !hasPermissions {
        fetchPermissions()
      }
    } else {
      guardpost.login { [weak self] result in
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          switch result {
          case .failure(let error):
            self.userState = .notLoggedIn
            self.permissionState = .notLoaded
            // Have to manually do this since we're not allowed @Published with enums
            self.objectWillChange.send()
            Failure
              .login(from: "SessionController", reason: error.localizedDescription)
              .log()
          case .success(let user):
            self.user = user
            print(user)
            
            Event
              .login(from: "SessionController")
              .log()
            
            self.fetchPermissions()
          }
        }
      }
    }
  }
  
  func fetchPermissionsIfNeeded() {
    // Request persmission if an app launch has happened or if it's been over 24 hours since the last permission request once the app enters the foreground
    guard shouldRefresh || !hasPermissions else { return }
    
    fetchPermissions()
  }
  
  func fetchPermissions() {
    // If there's no connection, use the persisted permissions
    // The re-fetch/re-store will be done the next time they open the app
    guard sessionState == .online else { return }
    
    // Don't repeatedly make the same request
    if case .loading = permissionState {
      return
    }
    
    // No point in requesting permissions when there's no user
    guard isLoggedIn else { return }
    
    permissionState = .loading
    permissionsService.permissions { result in
      DispatchQueue.main.async {
        switch result {
        case .failure(let error):
          Failure
            .fetch(from: "SessionController_Permissions", reason: error.localizedDescription)
            .log()
          
          self.permissionState = .error
        case .success(let permissions):
          // Check that we have a logged in user. Otherwise this is pointless
          guard let user = self.user else { return }
          
          // Update the date that we retrieved the permissions
          self.saveOrReplaceRefreshableUpdateDate()
          
          // Update the user
          self.user = user.with(permissions: permissions)
          // Ensure guardpost is aware, and hence the keychain is updated
          self.guardpost.updateUser(with: self.user)
        }
      }
    }
  }
  
  func logout() {
    guardpost.logout()
    userState = .notLoggedIn
    permissionState = .notLoaded

    user = nil
  }
  
  private func prepareSubscriptions() {
    $user.sink { [weak self] user in
      guard let self = self else { return }
      self.client = RWAPI(authToken: user?.token ?? "")
      self.permissionsService = PermissionsService(client: self.client)
    }
    .store(in: &subscriptions)
    
    connectionMonitor.pathUpdateHandler = { [weak self] path in
      guard let self = self else { return }
      
      let newState: SessionState = path.status == .satisfied ? .online : .offline
      
      if newState != self.sessionState {
        self.objectWillChange.send()
        self.sessionState = newState
        self.objectDidChange.send()
      }
      
      self.fetchPermissionsIfNeeded()
    }
    connectionMonitor.start(queue: .main)
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension SessionController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    UIApplication.shared.windows.first!
  }
}

// MARK: - Content Access Permissions
extension SessionController {
  func canPlay(content: Ownable) -> Bool {
    // Can always play free content
    if content.free {
      return true
    }
    // If the content isn't free then we must have a user
    guard let user = user else { return false }

    return content.professional ? user.canStreamPro : user.canStream
  }
}
