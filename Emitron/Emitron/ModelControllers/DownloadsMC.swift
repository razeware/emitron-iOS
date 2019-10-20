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
  
  // MARK: - Public Properties
  @Published var collectionProgress: CGFloat = 1.0
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
    print("episodesCounter: \(episodesCounter)")
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
  private var contentsMC: ContentsMC? {
    guard let dataManager = DataManager.current else { return nil }
    return dataManager.contentsMC
  }
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
    self.videosMC = VideosMC(user: self.user)
    super.init()

    loadDownloads()
  }

  // MARK: Public funcs
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
      print("not in files yet: \(content.name)")
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
      
      print("deleted: \(content.name)")
      completion?(true)


    } catch {
      self.state = .failed
      print("failed deleted: \(content.name)")
      if showCallback {
        self.callback?(false)
      }
      
      completion?(false)
    }
  }

  func deleteCollectionContents(withParent content: ContentDetailsModel, showCallback: Bool, completion: (() -> Void)? = nil) {
    
    print("CONTENT TO DELETE: \(content.name) & groups: \(content.groups.count)")
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
      print("FJ parent: \(parent.content.id) & & parentCont: \(parent.content.parentContent?.id) & content: \(content.id)")
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

  func saveDownload(with content: ContentDetailsModel) {
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
    content.isDownloading = true

    if content.isInCollection {
      self.loadCollectionVideoStream(of: content, localPath: destinationUrl)
    } else {
       self.loadIndividualVideoStream(for: content, localPath: destinationUrl)
    }
  }

  func saveCollection(with content: ContentDetailsModel) {
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

    downloadedContent = content
    episodesCounter += 1
    content.isDownloading = true
    saveNewDocument(with: destinationUrl, location: destinationUrl, content: content, attachment: nil, completion: nil)
  }

  func cancelDownload(with content: ContentDetailsModel) {
    cancelDownload = true
    
    data.forEach { download in
      if download.content.parentContent?.id == content.parentContent?.id {
        print("FJ ID: \(download.content.parentContent?.id) & download content: \(download.content.id) & content: \(content.id) & content parent: \(content.parentContent?.id) & name: \(download.content.name)")
        download.content.shouldCancel = true
      }
    }
    
    data.forEach { download in
      if download.content.shouldCancel {
        deleteDownload(with: download.content, showCallback: false, completion: nil)
      }
    }
    
//    if content.isInCollection {
//      self.deleteCollectionContents(withParent: content, showCallback: false, completion: nil)
//    } else {
//      self.deleteDownload(with: content, showCallback: false, completion: nil)
//    }
    
    downloadedModel = nil
    downloadedContent = nil
    downloadTask?.cancel()
    downloadsSession.invalidateAndCancel()
    downloadTask = nil
  }

  // MARK: Private funcs
  private func loadCollectionVideoStream(of content: ContentDetailsModel, localPath: URL) {
    guard let videoID = content.videoID else { return }

    videosMC.getDownloadVideofor(id: videoID) { response in
      switch response {
      case let .success(attachment):
        if let attachment = attachment.first, let streamURL = attachment.url {
          self.attachmentModel = attachment
          self.downloadTask = self.downloadsSession.downloadTask(with: streamURL, completionHandler: { (url, response, error) in

            DispatchQueue.main.async {
              self.state = .loading
            }

            if let url = response?.url {
              DispatchQueue.main.async {
                self.saveNewDocument(with: localPath, location: url, content: content, attachment: attachment) { downloadedContent in
                  print("save new doc completion: downloadedContent \(downloadedContent.name)")
                  print("content: \(downloadedContent.shouldCancel) & downloadedContent: \(downloadedContent.shouldCancel)")
                  self.handleSavedCompletion(of: downloadedContent)
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
  
  private func handleSavedCompletion(of content: ContentDetailsModel) {
    print("cancelDownload: \(cancelDownload) & isDownloading: \(content.isDownloading) & shouldCancel: \(content.shouldCancel)")
    
    guard content.shouldCancel else { return }
    
    print("FJ data: \(data.count) & content: \(content.name) & parent: \(content.parentContent?.name)")
    
    data.forEach { download in
      if download.content.shouldCancel {
        self.deleteDownload(with: download.content, showCallback: false, completion: nil)
      }
    }
    
    if !self.data.contains(where: { $0.content.shouldCancel }) {
      print("FJ REMOVED ALLL THE STUFF")
      self.cancelDownload = false
      self.state = .hasData
    }
  }

  private func loadIndividualVideoStream(for content: ContentDetailsModel, localPath: URL) {
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

      if let content = doc.videoData.content {
        
        print("FJ lcal content: \(content.name)")
        
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

  private func saveNewDocument(with fileURL: URL, location: URL, content: ContentDetailsModel, attachment: AttachmentModel?, completion: ((ContentDetailsModel)-> Void)? = nil) {

    guard !cancelDownload, !content.shouldCancel else {
      completion?(content)
      return
    }

    let doc = Document(fileURL: fileURL)
    doc.url = location
    doc.content = content

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
      
      content.isDownloading = false
      content.shouldCancel = self.cancelDownload
      print("saved: \(content.name) & cancelDown: \(self.cancelDownload) & shoudlCancel: \(content.shouldCancel)")
      
      guard !content.shouldCancel else {
        completion?(content)
        return
      }
      
      
      if content.isInCollection == true {
        self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: fileURL)
        self.episodesCounter -= 1
        self.collectionProgress = CGFloat(1.0 - (self.numGroupsCounter/self.totalNum))
      }
      
      // check if sending content from saveCollection call
      if content.isInCollection && self.finishedDownloadingCollection {
        self.state = .hasData
        self.callback?(true)
        print("FJ COMPLETION IN COLL")
        completion?(content)
      } else if !content.isInCollection {
        self.state = .hasData
        self.callback?(true)
        print("FJ COMPLETION NOT IN COLL")
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

    if let url = downloadTask.response?.url, let content = self.downloadedModel?.content {
      DispatchQueue.main.async {
        self.saveNewDocument(with: destinationUrl, location: url, content: content, attachment: nil)
      }
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
