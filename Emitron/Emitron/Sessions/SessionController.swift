// Copyright (c) 2022 Razeware LLC
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
// currently necessarily complete. It should probably be revisited,
// and rethought at a later stage. I'll put // TODO: here so that we might
// find it again.
protocol UserModelController {
  var objectDidChange: ObservableObjectPublisher { get }
  var user: User? { get }
  var client: RWAPI { get }
}

// Conforming to NSObject, so that we can conform to ASWebAuthenticationPresentationContextProviding
final class SessionController: UserModelController, ObservablePrePostFactoObject {
  private var subscriptions = Set<AnyCancellable>()

  // Managing the state of the current session
  @Published private(set) var sessionState: SessionState = .unknown
  @Published private(set) var userState: UserState = .notLoggedIn
  @Published private(set) var permissionState: PermissionState = .notLoaded
  
  // MARK: - ObservablePrePostFactoObject, UserModelController
  let objectDidChange = ObservableObjectPublisher()

  // MARK: - ObservablePrePostFactoObject
  @PublishedPrePostFacto var user: User? {
    didSet {
      if let user {
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

  private(set) var client: RWAPI

  // MARK: -

  private let guardpost: Guardpost
  private let connectionMonitor = NWPathMonitor()
  private(set) var permissionsService: PermissionsService
  
  var isLoggedIn: Bool { userState == .loggedIn }
  
  var hasPermissions: Bool {
    if case .loaded = permissionState {
      return true
    }
    return false
  }
  
  var hasPermissionToUseApp: Bool {
    user?.hasPermissionToUseApp == true
  }
  
  var hasCurrentDownloadPermissions: Bool {
    guard user?.canDownload == true else { return false }
    
    if
      case .loaded(let date) = permissionState,
      let permissionsLastConfirmedDate = date,
      Date.now.timeIntervalSince(permissionsLastConfirmedDate) < .videoPlaybackOfflinePermissionsCheckPeriod
    {
      return true
    }
    return false
  }
  
  // MARK: - Initializers
  @MainActor init(guardpost: Guardpost) {
    self.guardpost = guardpost

    let user = User.backdoor ?? guardpost.currentUser
    client = RWAPI(authToken: user?.token ?? "")
    permissionsService = .init(networkClient: client)

    self.user = user
    prepareSubscriptions()
  }
  
  // MARK: - Internal
  @MainActor func logIn() async throws {
    guard userState != .loggingIn else { return }
    
    userState = .loggingIn
    
    if isLoggedIn {
      if !hasPermissions {
        fetchPermissions()
      }
    } else {
      do {
        user = try await guardpost.logIn()
        Event
          .login(from: Self.self)
          .log()
        fetchPermissions()
      } catch {
        userState = .notLoggedIn
        permissionState = .notLoaded

        Failure
          .login(from: Self.self, reason: error.localizedDescription)
          .log()
      }
    }
  }
  
  func fetchPermissionsIfNeeded() {
    // Request permission if an app launch has happened or if it's been over 24 hours since the last permission request once the app enters the foreground
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

    Task {
      do {
        let permissions = try await permissionsService.permissions

        // Check that we have a logged in user. Otherwise this is pointless
        guard let user = self.user else { return }

        // Update the date that we retrieved the permissions
        self.saveOrReplaceRefreshableUpdateDate()

        // Update the user
        self.user = user.with(permissions: permissions)
        // Ensure guardpost is aware, and hence the keychain is updated
        self.guardpost.updateUser(with: self.user)
      } catch {
        enum Permissions { }
        Failure
          .fetch(from: Permissions.self, reason: error.localizedDescription)
          .log()

        self.permissionState = .error
      }
    }
  }
  
  func logOut() {
    guardpost.logOut()
    userState = .notLoggedIn
    permissionState = .notLoaded

    user = nil
  }

  private func prepareSubscriptions() {
    $user.sink { [weak self] user in
      guard let self else { return }
      self.client = RWAPI(authToken: user?.token ?? "")
      self.permissionsService = .init(networkClient: self.client)
    }
    .store(in: &subscriptions)
    
    connectionMonitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      
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

// MARK: - Refreshable
extension SessionController: Refreshable {
  var refreshableCheckTimeSpan: RefreshableTimeSpan { .short }
}

// MARK: - Content Access Permissions
extension SessionController {
  func canPlay(content: Ownable) -> Bool {
    // Can always play free content
    if content.free {
      return true
    }
    // If the content isn't free then we must have a user
    guard let user else { return false }

    return content.professional ? user.canStreamPro : user.canStream
  }
}
