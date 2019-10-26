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
  static let appExtension: String = "vdl"
  static let videoIDKey: String = "videoID"
  static let versionKey: String = "Version"
  static let videoKey: String = "Video"
  static let videoMP4Key: String = "Video.mp4"
  static let contentKey: String = "Content"
  static let dataKey: String = "Data"
  static let dataFilename: String = "video.data"
}

enum DownloadsAction {
  case save, delete, cancel
}

class DownloadsMC: NSObject, ObservableObject {

  // MARK: - Public Properties
  @Published var collectionProgress: CGFloat = 1.0
  var isEpisodeOnly = false
  var downloadedModel: DownloadModel?
  var callback: ((Bool) -> Void)?
  var downloadedContent: ContentDetailsModel? {
    willSet {
      objectWillChange.send(())
    }
  }

  // MARK: - Private Properties
  private lazy var downloadsSession: URLSession = {
    return URLSession(configuration: .default,
                      delegate: self,
                      delegateQueue: nil)
  }()

  private var finishedDownloadingCollection: Bool {
    return episodesCounter == 0
  }
  
  private var downloadTask: URLSessionDownloadTask?
  private var attachmentModel: AttachmentModel?
  private var destinationURL: URL?
  private var episodesCounter: Int = 1
  private var totalNum: Double = 0
  private var numGroupsCounter: Double = 0
  private var cancelDownload = false
  private let user: UserModel
  private let videosMC: VideosMC
  
  private(set) var localRoot: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }

  private(set) var data: [DownloadModel] = []

  // MARK: - Initializers
  init(user: UserModel) {
    self.user = user
    self.videosMC = VideosMC(user: self.user)
    super.init()

    loadDownloads()
  }

  // MARK: Public funcs

  // MARK: Delete
  func deleteDownload(with content: ContentDetailsModel, showCallback: Bool = true, completion: ((Bool) -> Void)? = nil) {

    let contentId: Int
    if let selectedDownload = data.first(where: { $0.content.id == content.id }) {
      contentId = selectedDownload.content.id
    } else if let parent = data.first(where: { $0.content.parentContent?.id == content.parentContent?.id }) {
      contentId = parent.content.id
    } else {
      completion?(false)
      return
    }

    let fileName: String
    if let videoId = content.videoID {
      fileName = "\(contentId).\(videoId).\(String.appExtension)"
    } else {
      fileName = "\(contentId).\(String.appExtension)"
    }

    guard let fileURL = localRoot?.appendingPathComponent(fileName, isDirectory: true),
          let index = data.firstIndex(where: { $0.content.id == contentId }) else { return }

    // If content is not yet saved in files, only need to remove it from data
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      self.data.remove(at: index)
      self.state = .hasData
      return
    }

    self.state = .loading

    do {
      try FileManager.default.removeItem(at: fileURL)
      self.data.remove(at: index)
      self.state = .hasData
      if showCallback {
        self.callback?(true)
      }

      completion?(true)


    } catch {
      self.state = .failed
      if showCallback {
        self.callback?(false)
      }

      completion?(false)
    }
  }

  func deleteCollectionContents(withParent content: ContentDetailsModel, showCallback: Bool, completion: (() -> Void)? = nil) {

    guard !content.groups.isEmpty else {
      deleteParent(with: content, completion: completion)
      return
    }

    content.groups.forEach { groupModel in
      groupModel.childContents.forEach { child in
        guard let videoId = child.videoID else {
          completion?()
          return
        }

        let fileName = "\(child.id).\(videoId).\(String.appExtension)"
        guard let fileURL = localRoot?.appendingPathComponent(fileName, isDirectory: true),
          let index = data.firstIndex(where: { $0.content.id == child.id }) else {
            completion?()
            return
        }

        self.state = .loading

        do {
          try FileManager.default.removeItem(at: fileURL)
          self.data.remove(at: index)
          self.state = .hasData

        } catch let error as NSError {
          print("Error: \(error.description)")
          self.state = .failed
        }
      }

      deleteParent(with: content, completion: completion)
    }
  }

  private func deleteParent(with content: ContentDetailsModel, completion: (() -> Void)?) {
    if let parent = self.data.first(where: { $0.content.id == content.id }) {
      let fileName = "\(parent.content.id).\(String.appExtension)"
      guard let fileURL = localRoot?.appendingPathComponent(fileName, isDirectory: true),
        let index = data.firstIndex(where: { $0.content.id == parent.content.id }) else {
            completion?()
            return
        }

      self.state = .loading

      do {
        try FileManager.default.removeItem(at: fileURL)
        self.data.remove(at: index)
        self.state = .hasData
        completion?()

      } catch let error as NSError {
        print("Error: \(error.description)")
        self.state = .failed
        completion?()
      }
    } else {
      completion?()
    }
  }
  
  private func localFilePath(for url: URL) -> URL {
    return localRoot!.appendingPathComponent(url.lastPathComponent)
  }

  // MARK: Save
  func saveDownload(with content: ContentDetailsModel, isEpisodeOnly: Bool) {
    guard !cancelDownload, let videoID = content.videoID else { return }

    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: nil)

    let fileName = "\(content.id).\(videoID).\(String.appExtension)"
    guard let destinationUrl = localRoot?.appendingPathComponent(fileName, isDirectory: true) else {
      if !content.isInCollection {
        self.callback?(false)
      } else if content.isInCollection && self.finishedDownloadingCollection {
        self.callback?(false)
      }
      return
    }

    self.destinationURL = destinationUrl

    self.state = .loading

    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else {

      if !content.isInCollection {
        self.state = .hasData
        self.callback?(false)
      } else if content.isInCollection && self.finishedDownloadingCollection {
        self.state = .hasData
        self.callback?(false)
      }

      return
    }

    downloadedContent = content

    if content.isInCollection {
      self.loadCollectionVideoStream(of: content, localPath: destinationUrl, isEpisodeOnly: isEpisodeOnly)
    } else {
       self.loadIndividualVideoStream(for: content, localPath: destinationUrl)
    }
  }

  func saveCollection(with content: ContentDetailsModel, isEpisodeOnly: Bool) {
    // reset episode counter back to 0 every time save new collection
    episodesCounter = 0

    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: nil)

    totalNum = Double(content.groups.count)
    numGroupsCounter = Double(content.groups.count)

    content.groups.forEach { groupModel in
      episodesCounter += groupModel.childContents.count
    }

    state = .loading

    // save parent content
    saveParent(with: content)

    content.groups.forEach { groupModel in
      groupModel.childContents.forEach { child in
        child.parentContent = content
        self.saveDownload(with: child, isEpisodeOnly: isEpisodeOnly)
      }
    }
  }

  private func saveParent(with content: ContentDetailsModel) {
    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                    delegate: self,
                                    delegateQueue: nil)

    let fileName = "\(content.id).\(String.appExtension)"
    guard let destinationUrl = localRoot?.appendingPathComponent(fileName, isDirectory: true) else { return }
    self.destinationURL = destinationUrl

    self.state = .loading

    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else { return }

    downloadedContent = content
    episodesCounter += 1
    saveNewDocument(with: destinationUrl, location: destinationUrl, data: nil, content: content, attachment: nil, isEpisodeOnly: false, completion: nil)
  }

  // MARK: Cancel
  func cancelDownload(with content: ContentDetailsModel, isEpisodeOnly: Bool) {
    cancelDownload = true

    data.forEach { download in
      if download.content.parentContent?.id == content.parentContent?.id {
        download.content.shouldCancel = true
      }
    }

    data.forEach { download in
      if download.content.shouldCancel {
        deleteDownload(with: download.content, showCallback: false, completion: nil)
      }
    }

    downloadedModel = nil
    downloadedContent = nil
    downloadTask?.cancel()
    downloadsSession.invalidateAndCancel()
    downloadTask = nil
  }

  // MARK: Private funcs
  private func loadCollectionVideoStream(of content: ContentDetailsModel, localPath: URL, isEpisodeOnly: Bool) {
    guard let videoID = content.videoID else { return }

    videosMC.getDownloadVideofor(id: videoID) { response in
      switch response {
      case let .success(attachment):
        if let attachment = attachment.first, let streamURL = attachment.url {
          self.attachmentModel = attachment
          self.downloadsSession.dataTask(with: streamURL) { (data, response, error) in
            DispatchQueue.main.async {
              self.state = .loading
            }

            if let url = response?.url {
              DispatchQueue.main.async {
                self.saveNewDocument(with: localPath, location: url, data: data, content: content, attachment: attachment, isEpisodeOnly: isEpisodeOnly) { downloadedContent in
                  self.handleSavedCompletion(of: downloadedContent)
                }
              }
            }
          }.resume()
        }

      case let .failure(error):
        print("error: \(error)")
        self.state = .failed
        if self.finishedDownloadingCollection {
          self.callback?(false)
        }
      }
    }
  }

  private func handleSavedCompletion(of content: ContentDetailsModel) {
    guard content.shouldCancel else { return }

    data.forEach { download in
      if download.content.shouldCancel {
        self.deleteDownload(with: download.content, showCallback: false, completion: nil)
      }
    }

    if !self.data.contains(where: { $0.content.shouldCancel }) {
      self.cancelDownload = false
      self.state = .hasData
    }
  }

  private func loadIndividualVideoStream(for content: ContentDetailsModel, localPath: URL) {
    guard let videoID = content.videoID else { return }
    videosMC.getDownloadVideofor(id: videoID) { [weak self] response in
    guard let self = self else { return }
      switch response {
      case let .success(attachment):
        if let attachment = attachment.first {
          self.attachmentModel = attachment
          self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: localPath)
        }

        if let streamURL = attachment.first?.url {
          self.downloadTask = self.downloadsSession.downloadTask(with: streamURL)
          self.downloadTask?.resume()
        }

      case let .failure(error):
        print("error: \(error)")
        self.state = .failed
        self.callback?(false)
      }
    }
  }
  
  func deleteAllDownloadedContent() {
    
    guard let root = localRoot else { return }

    do {
      let localDocs = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: [])

      for localDoc in localDocs where localDoc.pathExtension == .appExtension {
        try FileManager.default.removeItem(at: localDoc)
      }

      self.data = []

    } catch let error {
      Failure
      .fetch(from: "DownloadsMC", reason: error.localizedDescription)
      .log(additionalParams: nil)
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
        self.loadLocalContents(at: localDoc)
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

  private func loadLocalContents(at url: URL) {

    let doc = Document(fileURL: url)
    doc.open { [weak self] success in
      guard let self = self else { return }
      guard success else {
        self.state = .failed
        fatalError("Failed to open doc.")
      }

      if let content = doc.videoData.content {
        self.createDownloadModel(with: nil, content: content, isDownloaded: true, localPath: url)
      }

      self.state = .hasData

      doc.close() { success in
        guard success else {
          self.state = .failed
          fatalError("Failed to close doc.")
        }
      }
    }
  }

  private func createDownloadModel(with attachmentModel: AttachmentModel?, content: ContentDetailsModel, isDownloaded: Bool, localPath: URL) {
    let downloadModel = DownloadModel(attachmentModel: attachmentModel, content: content, isDownloaded: isDownloaded, localPath: localPath)

    if !data.contains(where: { $0.content.id == content.id }) && !cancelDownload {
      self.downloadedModel = downloadModel
      data.append(downloadModel)
    }

    self.state = .loading
  }

  private func updateModel(with id: Int,
                           progress: CGFloat) {

    if let downloadedModel = downloadedModel, let index = data.firstIndex(where: { $0.content.id == id }) {
      downloadedModel.downloadProgress = progress
      data[index] = downloadedModel
      self.state = .loading
    }
  }

  private func saveNewDocument(with fileURL: URL, location: URL, data: Data?, content: ContentDetailsModel, attachment: AttachmentModel?, isEpisodeOnly: Bool, completion: ((ContentDetailsModel)-> Void)? = nil) {

    guard !cancelDownload, !content.shouldCancel else {
      completion?(content)
      return
    }

    // add the parent content id so can filter the downloadsView content
    content.parentContentId = content.parentContent?.id

    let doc = Document(fileURL: fileURL)
    doc.url = location
    doc.content = content
    doc.data = data

    doc.save(to: fileURL, for: .forCreating) {
      [weak self] success in
      guard let `self` = self else { return }
      guard success else {
        completion?(content)
        Failure
        .fetch(from: "DownloadsMC", reason: "Error in saveNewDocument")
        .log(additionalParams: nil)
        fatalError("Failed to create file.")
      }

      content.shouldCancel = self.cancelDownload
      guard !content.shouldCancel else {
        completion?(content)
        return
      }

      if content.isInCollection {
        self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: fileURL)
        self.episodesCounter -= 1
        self.collectionProgress = CGFloat(1.0 - (self.numGroupsCounter/self.totalNum))
      }

      // If entire collection is being downloaded, only display success hud once every episode in collection is downloaded
      if content.isInCollection, !isEpisodeOnly, self.finishedDownloadingCollection {
        self.state = .hasData
        self.callback?(true)
        completion?(content)
        // If only downloading an episode or if downloading a screencast, then don't need to keep track of entire collection's progress
      } else if !content.isInCollection || isEpisodeOnly {
        self.state = .hasData
        self.callback?(true)
        completion?(content)
      }
    }
  }
}

extension DownloadsMC: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

    DispatchQueue.main.async {
      self.state = .loading
    }

    guard let destinationUrl = self.destinationURL else {
      DispatchQueue.main.async {
        self.state = .failed
        self.callback?(false)
      }
      return
    }

    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else {
      DispatchQueue.main.async {
        self.state = .hasData
        self.callback?(false)
      }
      return
    }
    
    guard let sourceURL = downloadTask.originalRequest?.url else { return }
    let newLocation = localFilePath(for: sourceURL)
    
    if let url = self.attachmentModel?.url {
      downloadsSession.dataTask(with: url) { (data, response, error) in

        if let content = self.downloadedModel?.content {
          DispatchQueue.main.async {
            self.saveNewDocument(with: destinationUrl, location: newLocation, data: data, content: content, attachment: nil, isEpisodeOnly: true)
          }
        }
      }.resume() 
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = CGFloat(bytesWritten)/CGFloat(totalBytesExpectedToWrite)
    DispatchQueue.main.async {
      if let model = self.downloadedModel, !model.content.isInCollection {
        self.updateModel(with: model.content.id, progress: progress)
      }
    }
  }
}
