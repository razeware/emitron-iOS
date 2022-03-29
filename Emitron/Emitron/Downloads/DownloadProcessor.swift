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

import Foundation
import Combine
import AVFoundation

protocol DownloadProcessorModel {
  var id: UUID { get }
  var localURL: URL? { get }
  var remoteURL: URL? { get }
}

protocol DownloadProcessorDelegate: AnyObject {
  func downloadProcessor(_ processor: DownloadProcessor, downloadModelForDownloadWithID downloadID: UUID) -> DownloadProcessorModel?
  func downloadProcessor(_ processor: DownloadProcessor, didStartDownloadWithID downloadID: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithID downloadID: UUID, didUpdateProgress progress: Double)
  func downloadProcessor(_ processor: DownloadProcessor, didFinishDownloadWithID downloadID: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, didCancelDownloadWithID downloadID: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithID downloadID: UUID, didFailWithError error: Error)
}

private extension URLSessionDownloadTask {
  var downloadID: UUID? {
    get { taskDescription.flatMap(UUID.init) }
    set { taskDescription = newValue?.uuidString ?? "" }
  }
}

private extension AVAssetDownloadTask {
  var downloadID: UUID? {
    get { taskDescription.flatMap(UUID.init) }
    set { taskDescription = newValue?.uuidString ?? "" }
  }
}

enum DownloadProcessorError: Error {
  case invalidArguments
  case unknownDownload
}

// Manage a list of files to download—either queued, in progress, paused or failed.
final class DownloadProcessor: NSObject {
  static let sessionIdentifier = "com.razeware.emitron.DownloadProcessor"
  static let sdBitrate = 250_000
  private var downloadQuality: Attachment.Kind {
    settingsManager.downloadQuality
  }
  private let settingsManager: SettingsManager

  init(settingsManager: SettingsManager) {
    self.settingsManager = settingsManager
    super.init()
    populateDownloadListFromSession()
  }
  
  private lazy var session: AVAssetDownloadURLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: DownloadProcessor.sessionIdentifier)
    // Uncommenting this causes the download task to fail with POSIX 22. But seemingly only with
    // Vimeo URLs. So that's handy.
    // config.isDiscretionary = true
    config.sessionSendsLaunchEvents = true
    return AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: .none)
  }()
  var backgroundSessionCompletionHandler: (() -> Void)?
  private var currentDownloads = [AVAssetDownloadTask]()
  private var throttleList = [UUID: Double]()
  weak var delegate: DownloadProcessorDelegate!
}

extension DownloadProcessor {
  func add(download: DownloadProcessorModel) throws {
    guard let remoteURL = download.remoteURL else { throw DownloadProcessorError.invalidArguments }
    let hlsAsset = AVURLAsset(url: remoteURL)
    var options: [String: Any]?
    if downloadQuality == .sdVideoFile {
      options = [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: DownloadProcessor.sdBitrate]
    }
    guard let downloadTask = session.makeAssetDownloadTask(asset: hlsAsset, assetTitle: "\(download.id))", assetArtworkData: nil, options: options) else { return }

    downloadTask.downloadID = download.id
    downloadTask.resume()
    
    currentDownloads.append(downloadTask)
    
    delegate.downloadProcessor(self, didStartDownloadWithID: download.id)
  }
  
  func cancelDownload(_ download: DownloadProcessorModel) throws {
    guard let downloadTask = currentDownloads.first(where: { $0.downloadID == download.id }) else { throw DownloadProcessorError.unknownDownload }
    
    downloadTask.cancel()
  }
  
  func cancelAllDownloads() {
    currentDownloads.forEach { $0.cancel() }
  }
  
  func pauseAllDownloads() {
    currentDownloads.forEach { $0.suspend() }
  }
  
  func resumeAllDownloads() {
    currentDownloads.forEach { $0.resume() }
  }
}

extension DownloadProcessor {
  private func getDownloadTasksFromSession() -> [AVAssetDownloadTask] {
    var tasks = [AVAssetDownloadTask]()
    // Use a semaphore to make an async call synchronous
    // --There's no point in trying to complete instantiating this class without this list.
    let semaphore = DispatchSemaphore(value: 0)
    session.getAllTasks { downloadTasks in

      let myTasks = downloadTasks as! [AVAssetDownloadTask]
      tasks = myTasks
      semaphore.signal()
    }
    
    _ = semaphore.wait(timeout: .distantFuture)
    
    return tasks
  }
  
  private func populateDownloadListFromSession() {
    currentDownloads = getDownloadTasksFromSession()
  }
}

extension DownloadProcessor: AVAssetDownloadDelegate {

  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {

    guard let downloadID = assetDownloadTask.downloadID else { return }

    var percentComplete = 0.0
    for value in loadedTimeRanges {
      let loadedTimeRange: CMTimeRange = value.timeRangeValue
      percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
    }
    
    if let lastReportedProgress = throttleList[downloadID],
      abs(percentComplete - lastReportedProgress) < 0.02 {
      // Less than a 2% change—it's a no-op
      return
    }
    throttleList[downloadID] = percentComplete
    delegate.downloadProcessor(self, downloadWithID: downloadID, didUpdateProgress: percentComplete)
  }

  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    guard
      let downloadID = assetDownloadTask.downloadID,
      let delegate = delegate
    else { return }

    let download = delegate.downloadProcessor(self, downloadModelForDownloadWithID: downloadID)
    guard let localURL = download?.localURL else { return }

    do {
      try FileManager.removeExistingFile(at: localURL)
      try FileManager.default.moveItem(at: location, to: localURL)
    } catch {
      delegate.downloadProcessor(self, downloadWithID: downloadID, didFailWithError: error)
    }
  }
}

extension DownloadProcessor: URLSessionDownloadDelegate {
  // When the background session has finished sending us events, we can tell the system we're done.
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    guard let backgroundSessionCompletionHandler = backgroundSessionCompletionHandler else { return }
    
    // Need to marshal back to the main queue
    DispatchQueue.main.async(execute: backgroundSessionCompletionHandler)
  }
  
  // Used to update the progress stats of a download task
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard let downloadID = downloadTask.downloadID else { return }
    
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    // We want to call the progress update every 2%
    if let lastReportedProgress = throttleList[downloadID],
      abs(progress - lastReportedProgress) < 0.02 {
      // Less than a 2% change—it's a no-op
      return
    }

    // Update the throttle list and make the delegate call
    throttleList[downloadID] = progress
    delegate.downloadProcessor(self, downloadWithID: downloadID, didUpdateProgress: progress)
  }
  
  // Download completed—move the file to the appropriate place and update the DB
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let downloadID = downloadTask.downloadID,
      let delegate = delegate else { return }
    
    let download = delegate.downloadProcessor(self, downloadModelForDownloadWithID: downloadID)
    guard let localURL = download?.localURL else { return }
    
    do {
      try FileManager.default.moveItem(at: location, to: localURL)
    } catch {
      delegate.downloadProcessor(self, downloadWithID: downloadID, didFailWithError: error)
    }
  }
  
  // Use this to handle and client-side download errors
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

    guard let downloadTask = task as? AVAssetDownloadTask, let downloadID = downloadTask.downloadID else { return }

    if let error = error as NSError? {
      let cancellationReason = (error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? NSNumber)?.intValue
      if cancellationReason == NSURLErrorCancelledReasonUserForceQuitApplication || cancellationReason == NSURLErrorCancelledReasonBackgroundUpdatesDisabled {
        // The download was cancelled for technical reasons, but we might be able to restart it...

        currentDownloads.removeAll { $0 == downloadTask }
      } else if error.code == NSURLErrorCancelled {
        // User-requested cancellation
        currentDownloads.removeAll { $0 == downloadTask }

        delegate.downloadProcessor(self, didCancelDownloadWithID: downloadID)
      } else {
        // Unknown error
        currentDownloads.removeAll { $0 == downloadTask }

        delegate.downloadProcessor(self, downloadWithID: downloadID, didFailWithError: error)
      }
    } else {
      // Success!
      currentDownloads.removeAll { $0 == downloadTask }

      delegate.downloadProcessor(self, didFinishDownloadWithID: downloadID)
    }
  }
}
