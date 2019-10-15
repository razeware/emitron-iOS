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
  static let contentKey: String = "Content"
  static let dataKey: String = "Data"
  static let dataFilename: String = "video.data"
}

enum DownloadsAction {
  case save, delete, cancel
}

class DownloadsMC: NSObject, ObservableObject {

  // MARK: - Properties
  lazy var downloadsSession: URLSession = {
    return URLSession(configuration: .default,
                      delegate: self,
                      delegateQueue: nil)
  }()

  var downloadTask: URLSessionDownloadTask?

  var attachmentModel: AttachmentModel?
  var downloadedModel: DownloadModel?
  var destinationURL: URL?
  var callback: ((Bool) -> Void)?
  var downloadedContent: ContentDetailsModel? {
    willSet {
      objectWillChange.send(())
    }
  }
  var finishedDownloadingCollection: Bool {
    return episodesCounter == 0
  }
  var episodesCounter: Int = 1
  var totalNum: Double = 0
  var numGroupsCounter: Double = 0
  @Published var collectionProgress: CGFloat = 0.0
  var activeDownloads = [ContentDetailsModel]()
  var cancelDownload = false
  let user: UserModel
  private(set) var localRoot: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
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
  func deleteDownload(with content: ContentDetailsModel, showCallback: Bool = true) {

    let contentId: Int
    if let selectedDownload = data.first(where: { $0.content.videoID == content.videoID }) {
      contentId = selectedDownload.content.id
    } else if let parent = data.first(where: { $0.content.videoID == nil }) {
      contentId = parent.content.id
    } else {
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

    self.state = .loading

    do {
      try FileManager.default.removeItem(at: fileURL)
      self.data.remove(at: index)
      self.state = .hasData
      if showCallback {
        self.callback?(true)
      }


    } catch {
      self.state = .failed
      if showCallback {
        self.callback?(false)
      }
    }
  }

  func deleteCollectionContents(withParent content: ContentDetailsModel, showCallback: Bool) {

    content.groups.forEach { groupModel in
      groupModel.childContents.forEach { child in

        guard let videoId = child.videoID else { return }

        let fileName = "\(child.id).\(videoId).\(String.appExtension)"
        guard let fileURL = localRoot?.appendingPathComponent(fileName, isDirectory: true),
              let index = data.firstIndex(where: { $0.content.videoID == child.videoID }) else { return }

        self.state = .loading

        do {
          try FileManager.default.removeItem(at: fileURL)
          self.data.remove(at: index)
          self.state = .hasData

        } catch {
          self.state = .failed
        }
      }

      // delete parent content
      if let parent = self.data.first(where: { $0.content.id == content.id }) {
        self.deleteDownload(with: parent.content, showCallback: showCallback)
      }
    }
  }

  func saveDownload(with content: ContentDetailsModel, videoId: Int? = nil) {
    guard !cancelDownload else { return }

    self.downloadedContent = content
    
    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: nil)

    let videoID: Int
    if let videoId = videoId {
      videoID = videoId
    } else if let videoId = content.videoID {
      videoID = videoId
    } else {
      return
    }

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

    let videosMC = VideosMC(user: self.user)

    if content.isInCollection {
      self.loadCollectionVideoStream(or: content, on: videosMC, localPath: destinationUrl, videoId: videoID)
    } else {
       self.loadIndividualVideoStream(for: content, on: videosMC, localPath: destinationUrl)
    }
  }

  func saveCollection(with content: ContentDetailsModel) {
    // reset episode counter back to 0 every time save new collection
    episodesCounter = 0

    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: nil)

    self.downloadedContent = content

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
        self.saveDownload(with: child)
      }
    }
  }

  func saveParent(with content: ContentDetailsModel) {
    // if session has been invalidated, recreate
      downloadsSession = URLSession(configuration: .default,
                                    delegate: self,
                                    delegateQueue: nil)

    let fileName = "\(content.id).\(String.appExtension)"
    guard let destinationUrl = localRoot?.appendingPathComponent(fileName, isDirectory: true) else { return }
    self.destinationURL = destinationUrl

    self.state = .loading

    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else { return }

    saveNewDocument(with: destinationUrl, location: destinationUrl, content: content) {
      let downloadModel = DownloadModel(attachmentModel: nil, content: content, isDownloaded: true, localPath: destinationUrl)
      self.data.append(downloadModel)
    }
  }

  func cancelDownload(with content: ContentDetailsModel) {
    cancelDownload = true
    downloadedModel = nil
    downloadedContent?.parentContent = nil
    downloadedContent = nil

    downloadTask?.cancel()
    downloadsSession.invalidateAndCancel()
    downloadTask = nil

    deleteCollectionContents(withParent: content, showCallback: false)

    activeDownloads.removeAll()
    print("activeDownloads count: \(activeDownloads.count)")
  }

  // MARK: Private funcs
  private func loadCollectionVideoStream(or content: ContentDetailsModel, on videosMC: VideosMC, localPath: URL, videoId: Int?) {

    let videoID: Int
    if let videoId = videoId {
      videoID = videoId
    } else if let videoId = content.videoID {
      videoID = videoId
    } else {
      return
    }

    videosMC.getDownloadVideofor(id: videoID) { response in
      switch response {
      case let .success(attachment):
        if let attachment = attachment.first {
          self.attachmentModel = attachment
          self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: localPath)
        }

        if let streamURL = attachment.first?.url {
          self.downloadTask = self.downloadsSession.downloadTask(with: streamURL, completionHandler: { (url, response, error) in

            DispatchQueue.main.async {
              self.state = .loading
            }

            if let url = response?.url {
              DispatchQueue.main.async {
                self.saveNewDocument(with: localPath, location: url, content: content) {
                  if self.cancelDownload {
                    self.activeDownloads.forEach { model in
                      self.deleteDownload(with: model, showCallback: false)
                    }

                    self.data.forEach { model in

                      if let videoID = content.groups.first?.childContents.first?.videoID, model.content.id == videoID {
                        self.deleteDownload(with: model.content, showCallback: false)
                      }
                    }

                    self.activeDownloads.removeAll()
                    self.downloadedModel = nil
                    self.downloadedContent?.parentContent = nil
                    self.downloadedContent = nil
                  }
                }
              }
            }
          })

          self.downloadTask?.resume()
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

  private func loadIndividualVideoStream(for content: ContentDetailsModel, on videosMC: VideosMC, localPath: URL) {
    guard let videoID = content.videoID else { return }
    videosMC.getDownloadVideofor(id: videoID) { response in
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
      
      print("FJ doc.videoData.content: \(doc.videoData.content) & vid url: \(doc.videoData.url)")
      
      if let content = doc.videoData.content {
        self.createDownloadModel(with: nil, content: content, isDownloaded: true, localPath: url)
      }
      
      doc.close() { success in
        guard success else {
          self.state = .failed
          fatalError("Failed to close doc.")
        }
      }
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
          self.createDownloadModel(with: attachmentModel, content: content, isDownloaded: isDownloaded, localPath: localPath)
          self.state = .hasData
        }
      }
    }
  }

  private func createDownloadModel(with attachmentModel: AttachmentModel?, content: ContentDetailsModel, isDownloaded: Bool, localPath: URL) {
    let downloadModel = DownloadModel(attachmentModel: attachmentModel, content: content, isDownloaded: isDownloaded, localPath: localPath)
    self.downloadedModel = downloadModel
    data.append(downloadModel)
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

  private func saveNewDocument(with fileURL: URL, location: URL, content: ContentDetailsModel, completion: (()-> Void)? = nil) {

    guard !cancelDownload else { return }

    let doc = Document(fileURL: fileURL)
    doc.url = location
    doc.content = content
    print("FJ content: \(content) & url: \(fileURL)")

    doc.save(to: fileURL, for: .forCreating) {
      [weak self] success in
      guard let `self` = self else { return }
      guard success else {
        completion?()
        Failure
        .fetch(from: "DownloadsMC", reason: "Error in saveNewDocument")
        .log(additionalParams: nil)
        fatalError("Failed to create file.")
      }

      if content.isInCollection == true {
        self.episodesCounter -= 1
        self.collectionProgress = CGFloat(1.0 - (self.numGroupsCounter/self.totalNum))
      }

      self.activeDownloads.append(content)

      // check if sending content from saveCollection call
      if content.isInCollection && self.finishedDownloadingCollection {
        self.state = .hasData
        self.callback?(true)
      } else if !content.isInCollection {
        self.state = .hasData
        self.callback?(true)
      }

      completion?()
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

    if let url = downloadTask.response?.url, let content = self.downloadedContent {
      DispatchQueue.main.async {
        self.saveNewDocument(with: destinationUrl, location: url, content: content)
      }
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    let progress = CGFloat(bytesWritten)/CGFloat(totalBytesExpectedToWrite)
    DispatchQueue.main.async {
      if let model = self.downloadedModel, !model.content.isInCollection {
        self.updateModel(with: model.content.id, progress: 1.0 - progress)
      }
    }
  }
}
