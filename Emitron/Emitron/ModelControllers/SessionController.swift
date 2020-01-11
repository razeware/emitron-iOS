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

import AuthenticationServices
import Foundation
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
  var refreshableUserDefaultsKey: String = "UserDefaultsRefreshable\(String(describing: SessionController.self))"
  var refreshableCheckTimeSpan: RefreshableTimeSpan = .short
  
  private var subscriptions = Set<AnyCancellable>()

  private(set) var state = DataState.initial
  
  // Once again, there appears to be some kind of issue with
  // @Published. In theory, user should be @Published, but it
  // causes a EXC_BAD_ACCESS when accessed from outside this
  // class. We can get around this using this extra accessor
  // and keeping the @Published property for internal use.
  @PublishedPrePostFacto private var internalUser: User?
  let objectDidChange = ObservableObjectPublisher()
  var user: User? {
    return internalUser
  }
  
  private let guardpost: Guardpost
  private let connectionMonitor = NWPathMonitor()
  private(set) var client: RWAPI
  private(set) var permissionsService: PermissionsService
  
  var isLoggedIn: Bool {
    user != nil
  }
  
  var hasPermissions: Bool {
    user?.permissions != nil
  }
  
  var hasPermissionToUseApp: Bool {
    user?.hasPermissionToUseApp ?? false
  }
  
  // MARK: - Initializers
  init(guardpost: Guardpost) {
    dispatchPrecondition(condition: .onQueue(.main))
    self.guardpost = guardpost
    let user = guardpost.currentUser
    self.internalUser = user
    self.client = RWAPI(authToken: user?.token ?? "")
    self.permissionsService = PermissionsService(client: self.client)
    super.init()
    
    let queue = DispatchQueue(label: "Monitor")
    connectionMonitor.start(queue: queue)
    
    prepareSubscriptions()
  }
  
  // MARK: - Internal
  func login() {
    if state == .loading { return }
    
    state = .loading
    guardpost.presentationContextDelegate = self
    
    if isLoggedIn {
      if !hasPermissions {
        fetchPermissions()
      } else {
        state = .hasData
      }
    } else {
      guardpost.login { [weak self] result in
        guard let self = self else { return }
        
        switch result {
        case .failure(let error):
          self.state = .failed
          // Have to manually do this since we're not allowed @Published with the enum
          self.objectWillChange.send()
          Failure
            .login(from: "SessionController", reason: error.localizedDescription)
            .log(additionalParams: nil)
        case .success(let user):
          self.internalUser = user
          
          Event
            .login(from: "SessionController")
            .log(additionalParams: nil)
          
          self.fetchPermissions()
        }
      }
    }
  }
  
  func fetchPermissionsIfNeeded() {
    // Request persmission if an app launch has happened or if it's been oveer 24 hours since the last permission request once the app enters the foreground
    guard shouldRefresh || !hasPermissions else { return }
    
    fetchPermissions()
  }
  
  func fetchPermissions() {
    // If there's no connection, use the persisted permissions
    // The re-fetch/re-store will be done the next time they open the app
    guard connectionMonitor.currentPath.status == .satisfied else { return }
    
    // Don't repeatedly make the same request
    if state == .loadingAdditional { return }
    
    // No point in requesting permissions when there's no user
    if !isLoggedIn { return }
    
    state = .loadingAdditional
    permissionsService.permissions { result in
      switch result {
      case .failure(let error):
        Failure
          .fetch(from: "SessionController_Permissions", reason: error.localizedDescription)
          .log(additionalParams: nil)
        
        self.state = .failed
      case .success(let permissions):
        // Check that we have a logged in user. Otherwise this is pointless
        guard let user = self.user else { return }
        
        self.state = .hasData
        // Update the user
        self.internalUser = user.with(permissions: permissions)
        // Ensure guardpost is aware, and hence the keychain is updated
        self.guardpost.updateUser(with: user)
        self.saveOrReplaceRefreshableUpdateDate()
      }
    }
  }
  
  func logout() {
    guardpost.logout()
    UserDefaults.standard.deleteAllFilters()
    self.state = .initial
    
    internalUser = nil
  }
  
  private func prepareSubscriptions() {
    $internalUser.sink { [weak self] (user) in
      guard let self = self else { return }
      self.client = RWAPI(authToken: user?.token ?? "")
      self.permissionsService = PermissionsService(client: self.client)
    }
    .store(in: &subscriptions)
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension SessionController: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.windows.first!
  }
}

