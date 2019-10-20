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

import Foundation
import SwiftUI
import Combine

class VideosMC: NSObject, ObservableObject {
  
  // MARK: - Properties
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }
  
  private let client: RWAPI
  private let user: UserModel
  private let videoService: VideosService
  private let contentsService: ContentsService
  private var token: String?
  private(set) var data: AttachmentModel?
  private(set) var streamURL: URL?
  
  // MARK: - Initializers
  init(user: UserModel) {
    self.user = user
    //TODO: Probably need to handle this better
    self.client = RWAPI(authToken: user.token)
    self.videoService = VideosService(client: self.client)
    self.contentsService = ContentsService(client: self.client)
    self.token = UserDefaults.standard.playbackToken
    
    super.init()    
  }
  
  // MARK: - Internal
  func fetchBeginPlaybackToken(completion: @escaping (Bool, String?) -> Void) {
    contentsService.getBeginPlaybackToken { result in
      switch result {
      case .failure(let error):
        Failure
          .fetch(from: "VideosMC_PlaybackToken", reason: error.localizedDescription)
          .log(additionalParams: nil)
        //TODO: Ask user to re-confirm
        completion(false, nil)
      case .success(let token):
        UserDefaults.standard.setPlaybackToken(token: token)
        self.token = token
        completion(true, token)
      }
    }
  }
  
  @objc func reportUsageStatistics(progress: Int, contentID: Int) {
    
    guard let playbackToken = token else {
      fetchBeginPlaybackToken { [weak self] (success, token) in
        guard let self = self else { return }
        if success {
          self.reportUsageStatistics(progress: progress, contentID: contentID)
        } else {
          //TODO: Ask user to re-confirm
        }
      }
      return
    }
    
    contentsService.reportPlaybackUsage(for: contentID, progress: progress, playbackToken: playbackToken) { result in
      switch result {
      case .failure(let error):
        Failure
        .fetch(from: "VideosMC_PlaybackUsage", reason: error.localizedDescription)
        .log(additionalParams: nil)
        
        //TODO: Stop playback, ask use to re-play the video
      case .success(_): break
        //TODO: Anything to do when we get back usage statistics?
      }
    }
  }
  
  func loadVideoStream(for id: Int, completion: (() -> Void)? = nil) {
    if case(.loading) = state {
      completion?()
      return
    }
    
    state = .loading

    videoService.getVideoStream(for: id) { [weak self] result in
      guard let self = self else {
        completion?()
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "VideosMC", reason: error.localizedDescription)
          .log(additionalParams: ["Id": "\(id)"])
        completion?()
      case .success(let attachment):
        self.data = attachment
        self.streamURL = attachment.url
        self.state = .hasData
        completion?()
      }
    }
  }
  
  func getVideoStream(for id: Int,
                      completion: @escaping (_ response: Result<StreamVideoRequest.Response, RWAPIError>) -> Void) {
    if case(.loading) = state {
      return
    }
    
    state = .loading
    videoService.getVideoStream(for: id) { [weak self] result in
      completion(result)
      
      guard let self = self else {
        return
      }
      
      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "VideosMC", reason: error.localizedDescription)
          .log(additionalParams: ["VideoID": "\(id)"])
      case .success(let attachment):
        self.data = attachment
        self.streamURL = attachment.url
        self.state = .hasData
      }
    }
  }
  
  func getDownloadVideofor(id: Int,
                           completion: @escaping (_ response: Result<DownloadVideoRequest.Response, RWAPIError>) -> Void) {
    state = .loading
    videoService.getVideoDownload(for: id) { [weak self] result in
      completion(result)

      guard let self = self else {
        return
      }

      switch result {
      case .failure(let error):
        self.state = .failed
        Failure
          .fetch(from: "VideosMC", reason: error.localizedDescription)
          .log(additionalParams: ["VideoID": "\(id)"])
      case .success(let attachment):
        self.data = attachment.first
        self.state = .hasData
      }
    }
  }
}
