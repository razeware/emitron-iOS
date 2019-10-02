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

enum DownloadsAction {
  case save, delete
}

class DownloadsMC: NSObject, ObservableObject {
  
  // MARK: - Properties
  lazy var downloadsSession: URLSession = {
    return URLSession(configuration: .default,
                      delegate: self,
                      delegateQueue: nil)
  }()

  var attachmentModel: AttachmentModel?
  var downloadedModel: DownloadModel?
  var destinationURL: URL?
  var callback: ((Bool) -> Void)?
  
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

    loadDownloads()
  }
  
  // MARK: Public funcs
  func deleteDownload(with videoID: Int) {
    guard let selectedVideo = data.first(where: { $0.content.videoID == videoID }) else { return }
    let fileName = "\(selectedVideo.content.id).\(selectedVideo.content.videoID).\(String.appExtension)"
    guard let fileURL = localRoot?.appendingPathComponent(fileName, isDirectory: true),
          let index = data.firstIndex(where: { $0.content.id == selectedVideo.content.id }) else { return }
    
    self.state = .loading
    
    do {
      try FileManager.default.removeItem(at: fileURL)
      
      self.data.remove(at: index)
      self.state = .hasData
      self.callback?(true)
      
    } catch {
      self.state = .failed
      self.callback?(false)
    }
  }
  
  func saveDownload(with content: ContentSummaryModel) {
    let fileName = "\(content.id).\(content.videoID).\(String.appExtension)"
    guard let destinationUrl = localRoot?.appendingPathComponent(fileName, isDirectory: true) else {
      self.callback?(false)
      return
    }
    
    self.destinationURL = destinationUrl
    self.state = .loading
    
    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else {
      self.state = .hasData
      self.callback?(false)
      return
    }
    
    let videosMC = VideosMC(user: self.user, contentId: content.id)
    self.loadVideoStream(for: content, on: videosMC, localPath: destinationUrl)
  }
  
  // MARK: Private funcs
  private func loadVideoStream(for content: ContentSummaryModel, on videosMC: VideosMC, localPath: URL) {
    videosMC.getDownloadVideofor(id: content.videoID) { response in
      switch response {
      case let .success(attachment):
        if let attachment = attachment.first {
          self.attachmentModel = attachment
          self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: localPath)
        }
        
        if let streamURL = attachment.first?.url {
          self.downloadsSession.downloadTask(with: streamURL).resume()
        }
        
      case let .failure(error):
        print("error: \(error)")
        self.state = .failed
        self.callback?(false)
      }
    }
  }
  
  private func loadDownloads() {
    
    guard let root = localRoot else {
      self.state = .failed
      return
    }
    
    self.state = .loading
    do {
      let localDocs = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: [])
      
      for localDoc in localDocs where localDoc.pathExtension == .appExtension {
        
        let lastPathComponents = localDoc.lastPathComponent.components(separatedBy: ".").dropLast()
        if let contentIDString = lastPathComponents.first,
          let contentID = Int(contentIDString),
          let videoIDString = lastPathComponents.last,
          let videoID = Int(videoIDString) {
          let videoMC = VideosMC(user: self.user, contentId: contentID)
          videoMC.loadVideoStream(for: videoID) {
            if let attachmentModel = videoMC.data {
              DispatchQueue.main.async {
                self.loadContents(contentID: contentID, videoID: videoID, attachmentModel: attachmentModel, isDownloaded: true, localPath: localDoc)
              }
            }
          }
        }
      }
      
      self.state = .hasData
      
    } catch let error {
      self.state = .failed
      self.callback?(false)
      
      Failure
      .fetch(from: "DownloadsMC", reason: error.localizedDescription)
      .log(additionalParams: nil)
    }
  }
  
  private func loadContents(contentID: Int, videoID: Int, attachmentModel: AttachmentModel, isDownloaded: Bool, localPath: URL) {
    let client = RWAPI(authToken: Guardpost.current.currentUser?.token ?? "")
    let contentsService = ContentsService(client: client)
    contentsService.contentDetails(for: contentID) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .failure(let error):
        self.state = .failed
        self.callback?(false)
        Failure
          .fetch(from: "DocumentsMC", reason: error.localizedDescription)
          .log(additionalParams: nil)
      case .success(let content):
        DispatchQueue.main.async {
          self.createDownloadModel(with: attachmentModel, content: ContentSummaryModel(contentDetails: content, videoID: videoID), isDownloaded: isDownloaded, localPath: localPath)
          self.state = .hasData
        }
      }
    }
  }
  
  private func createDownloadModel(with attachmentModel: AttachmentModel, content: ContentSummaryModel, isDownloaded: Bool, localPath: URL) {
    let downloadModel = DownloadModel(attachmentModel: attachmentModel, content: content, isDownloaded: isDownloaded, localPath: localPath)
    self.downloadedModel = downloadModel
    data.append(downloadModel)
    self.state = .loading
  }
  
  private func updateModel(with id: Int, progress: CGFloat) {

    if let downloadedModel = downloadedModel, let index = data.firstIndex(where: { $0.content.id == id }) {
      downloadedModel.downloadProgress = progress
      data[index] = downloadedModel
      self.state = .loading
    }
  }
}

extension DownloadsMC: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    
    DispatchQueue.main.async {
      self.state = .loading
    }
    
    guard let destinationUrl = self.destinationURL else {
      self.state = .failed
      self.callback?(false)
      return
    }
    
    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else {
      DispatchQueue.main.async {
        self.state = .hasData
        self.callback?(false)
      }
      return
    }
    
    if let data = downloadTask.response?.url?.dataRepresentation {
      DispatchQueue.main.async {
        if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
            self.state = .hasData
            self.callback?(true)
        }
      }
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = CGFloat(bytesWritten)/CGFloat(totalBytesExpectedToWrite)
    DispatchQueue.main.async {
      if let model = self.downloadedModel {
        self.updateModel(with: model.content.id, progress: 1.0 - progress)
      }
    }
  }
}

