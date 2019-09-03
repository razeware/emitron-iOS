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
import SwiftyJSON

extension String {
  static let appExtension: String = "ptk"
  static let videoIDKey: String = "videoID"
  static let photoKey: String = "Photo"
  static let thumbnailKey: String = "Thumbnail"
}

class DownloadsMC: NSObject, ObservableObject {
  
  // MARK: - Properties
  let user: UserModel
  private(set) var localRoot: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    didSet {
      objectWillChange.send(())
    }
  }
  
  private(set) var data: [DownloadModel] = []
  private(set) var numTutorials: Int = 0
  
  // Pagination
  private var currentPage: Int = 1
  private let startingPage: Int = 1
  private(set) var defaultPageSize: Int = 20
  
  // Parameters
  private var defaultParameters: [Parameter] {
    return Param.filters(for: [.contentTypes(types: [.collection, .screencast])])
  }
    
  // MARK: - Initializers
  init(user: UserModel) {
    self.user = user
    super.init()

    loadContents()
  }
  
  // MARK: Public funcs
  func deleteDownload(with videoID: Int) {
    guard let selectedVideo = data.first(where: { $0.content.videoID == videoID }) else { return }
    let filename = String(format: "%d.%d.%@", selectedVideo.content.id, videoID, String.appExtension)
    guard let fileURL = localRoot?.appendingPathComponent(filename, isDirectory: false) else { return }
    
    do {
      try FileManager.default.removeItem(at: fileURL)
      
      for (index, model) in data.enumerated() {
        if model.content.id == selectedVideo.content.id {
          data.remove(at: index)
          self.state = .hasData
        }
      }

    } catch {
      self.state = .failed
      fatalError("Couldn't remove file.")
    }
  }
  
  func saveDownload(with videoID: Int, content: ContentSummaryModel) {
    let filename = String(format: "%d.%d.%@", content.id, videoID, String.appExtension)
    guard let destinationUrl = localRoot?.appendingPathComponent(filename, isDirectory: false) else { return }
    
    if FileManager().fileExists(atPath: destinationUrl.path) {
      print("file already exists")
      // TODO show error hud
      
    } else {
      let videoMC = VideosMC(user: self.user)
      videoMC.loadVideoStream(for: videoID) {
        if let streamURL = videoMC.streamURL {
          self.load(url: streamURL) { (data, response, error) in
            if let error = error {
              // TODO show error hud
              self.state = .failed
              Failure
                .fetch(from: "DocumentsMC", reason: error.localizedDescription)
                .log(additionalParams: nil)
              return
            }
            
            if let response = response as? HTTPURLResponse {
              if response.statusCode == 200 {
                DispatchQueue.main.async {
                  if let data = data {
                    if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic){
                      if let attachmentModel = videoMC.data {
                        let downloadModel = DownloadModel(video: attachmentModel, content: content)
                        self.data.append(downloadModel)
                        // TODO show success hud
                        self.state = .hasData
                      }
                    } else {
                      // TODO show error hud
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  
  // MARK: Private funcs
  private func load(url streamURL: URL, completion: @escaping ((Data?, URLResponse?, Error?) -> Void)) {
    var request = URLRequest(url: streamURL)
    request.httpMethod = "GET"
    _ = URLSession(configuration: .default).dataTask(with: request, completionHandler: { (data, response, error) in
      completion(data, response, error)
    }).resume()
  }
  
  private func loadContents() {
    guard let root = localRoot else { return }
    do {
      let localDocs = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: [])
      
      for localDoc in localDocs where localDoc.pathExtension == .appExtension {
        let lastPathComponents = localDoc.lastPathComponent.components(separatedBy: ".").dropLast()
        
        if let contentIDString = lastPathComponents.first, let contentID = Int(contentIDString), let videoIDString = lastPathComponents.last, let videoID = Int(videoIDString) {
          let videoMC = VideosMC(user: self.user)
          videoMC.loadVideoStream(for: videoID) {
            
            if let attachmentModel = videoMC.data {
              let client = RWAPI(authToken: Guardpost.current.currentUser?.token ?? "")
              let contentsService = ContentsService(client: client)
              contentsService.contentSummary(for: contentID) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                  self.state = .failed
                  Failure
                    .fetch(from: "DocumentsMC", reason: error.localizedDescription)
                    .log(additionalParams: nil)
                case .success(let content):
                  let downloadModel = DownloadModel(video: attachmentModel, content: content)
                  self.data.append(downloadModel)
                  // TODO show success hud
                  self.state = .hasData
                }
              }
            }
          }
        }
      }
    } catch let error {
      self.state = .failed
      fatalError("Couldn't load local content. \(error.localizedDescription)")
    }
  }
}
