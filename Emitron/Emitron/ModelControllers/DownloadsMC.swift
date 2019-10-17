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
  let videosMC: VideosMC
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
  func deleteDownload(with content: ContentDetailsModel, showCallback: Bool = true) {
    
    print("FJ DELETING CONTENT: \(content.name)")
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
    
    // If content is not yet saved in files, only need to remove it from data 
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("filename: \(fileName)")
      self.data.remove(at: index)
      return
    }

    self.state = .loading

    do {
      try FileManager.default.removeItem(at: fileURL)
      self.data.remove(at: index)
      
      if let activeDownloadIndex = self.activeDownloads.firstIndex(where: { $0.id == contentId }) {
        self.activeDownloads.remove(at: activeDownloadIndex)
      }
      print("FJ REMOVE: \(content.name)")
      
      self.state = .hasData
      if showCallback {
        self.callback?(true)
      }


    } catch {
      print("FJ FAILED TO REMOVE: \(content.name)")
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
          
          if let activeDownloadIndex = self.activeDownloads.firstIndex(where: { $0.videoID == child.videoID }) {
            self.activeDownloads.remove(at: activeDownloadIndex)
          }
          print("FJ REMOVE: \(content.name)")
          
          self.state = .hasData

        } catch {
          print("FJ FAILED TO REMOVE: \(content.name)")
          self.state = .failed
        }
      }
    }

    // delete parent content
    if let parent = self.data.first(where: { $0.content.videoID == nil }) {
      print("FJ IS IN PARENT DELETE")
      self.deleteDownload(with: parent.content, showCallback: showCallback)
    }
  }

  func saveDownload(with content: ContentDetailsModel) {
    guard !cancelDownload, let videoID = content.videoID else { return }
    self.downloadedContent = content

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

    if content.isInCollection {
      self.loadCollectionVideoStream(or: content, localPath: destinationUrl)
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
    downloadedContent = content
    episodesCounter += 1

    // if session has been invalidated, recreate
    downloadsSession = URLSession(configuration: .default,
                                    delegate: self,
                                    delegateQueue: nil)

    let fileName = "\(content.id).\(String.appExtension)"
    guard let destinationUrl = localRoot?.appendingPathComponent(fileName, isDirectory: true) else { return }
    self.destinationURL = destinationUrl

    self.state = .loading

    guard !FileManager.default.fileExists(atPath: destinationUrl.path) else { return }

    saveNewDocument(with: destinationUrl, location: destinationUrl, content: content, attachment: nil, completion: nil)
  }

  func cancelDownload(with content: ContentDetailsModel) {
    cancelDownload = true
    
    if content.isInCollection {
      deleteCollectionContents(withParent: content, showCallback: false)
    } else {
      deleteDownload(with: content, showCallback: false)
    }
    
    downloadedModel = nil
    downloadedContent = nil
    downloadTask?.cancel()
    downloadsSession.invalidateAndCancel()
    downloadTask = nil

     // reset cancel download bool so can donwload other colletions & screencasts
    if activeDownloads.count == 0 {
      cancelDownload = false
      state = .hasData
    }
    
    print("fj data count: \(data.count) & active: \(activeDownloads.count)")
  }

  // MARK: Private funcs
  private func loadCollectionVideoStream(or content: ContentDetailsModel, localPath: URL) {
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
                self.saveNewDocument(with: localPath, location: url, content: content, attachment: attachment) {

                  // Protect against timing issues if download is already in progress when cancel downloads
                  if self.cancelDownload {
                    self.activeDownloads.forEach { model in
                      self.deleteDownload(with: model, showCallback: false)
                    }
                    
                    print("fj in closure: \(self.data.count) & self.activeDownloads: \(self.activeDownloads.count)")

                    self.downloadedModel = nil
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
        print("localDoc: \(localDoc)")
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
    self.downloadedModel = downloadModel
    
    if !data.contains(where: { $0.content.id == content.id }) {
      data.append(downloadModel)
      print("FJ APPEND CONTENT: \(downloadModel.content.name)")
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

  private func saveNewDocument(with fileURL: URL, location: URL, content: ContentDetailsModel, attachment: AttachmentModel?, completion: (()-> Void)? = nil) {

    guard !cancelDownload else {
      completion?()
      return
    }

    let doc = Document(fileURL: fileURL)
    doc.url = location
    doc.content = content

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
        self.createDownloadModel(with: attachment, content: content, isDownloaded: true, localPath: fileURL)
        self.episodesCounter -= 1
        self.collectionProgress = CGFloat(1.0 - (self.numGroupsCounter/self.totalNum))
      }

      self.activeDownloads.append(content)
      
      print("FJ self.activeDownloads: \(self.activeDownloads.count) & data: \(self.data.count)")
      
      guard !self.cancelDownload else {
        completion?()
        return
      }

      // check if sending content from saveCollection call
      if content.isInCollection && self.finishedDownloadingCollection {
        self.state = .hasData
        self.callback?(true)
        completion?()
      } else if !content.isInCollection {
        self.state = .hasData
        self.callback?(true)
        completion?()
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
        self.updateModel(with: model.content.id, progress: 1.0 - progress)
      }
    }
  }
}
