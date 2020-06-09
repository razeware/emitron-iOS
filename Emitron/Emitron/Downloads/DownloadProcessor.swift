// Copyright (c) 2019 Razeware LLC
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

protocol DownloadProcessorModel {
  var id: UUID { get }
  var localUrl: URL? { get }
  var remoteUrl: URL? { get }
}

protocol DownloadProcessorDelegate: AnyObject {
  func downloadProcessor(_ processor: DownloadProcessor, downloadModelForDownloadWithId downloadId: UUID) -> DownloadProcessorModel?
  func downloadProcessor(_ processor: DownloadProcessor, didStartDownloadWithId downloadId: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didUpdateProgress progress: Double)
  func downloadProcessor(_ processor: DownloadProcessor, didFinishDownloadWithId downloadId: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, didCancelDownloadWithId downloadId: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, didPauseDownloadWithId downloadId: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, didResumeDownloadWithId downloadId: UUID)
  func downloadProcessor(_ processor: DownloadProcessor, downloadWithId downloadId: UUID, didFailWithError error: Error)
}

private extension URLSessionDownloadTask {
  var downloadId: UUID? {
    get {
      guard let taskDescription = taskDescription else { return .none }
      return UUID(uuidString: taskDescription)
    }
    set {
      taskDescription = newValue?.uuidString ?? ""
    }
  }
}

enum DownloadProcessorError: Error {
  case invalidArguments
  case unknownDownload
}

// Manage a list of files to download—either queued, in progresss, paused or failed.
final class DownloadProcessor: NSObject {
  static let sessionIdentifier = "com.razeware.emitron.DownloadProcessor"
  
  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: DownloadProcessor.sessionIdentifier)
    // Uncommenting this causes the download task to fail with POSIX 22. But seemingly only with
    // Vimeo URLs. So that's handy.
    //config.isDiscretionary = true
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: self, delegateQueue: .none)
  }()
  var backgroundSessionCompletionHandler: (() -> Void)?
  private var currentDownloads = [URLSessionDownloadTask]()
  private var throttleList = [UUID: Double]()
  weak var delegate: DownloadProcessorDelegate!
  
  override init() {
    super.init()
    populateDownloadListFromSession()
  }
}

extension DownloadProcessor {
  func add(download: DownloadProcessorModel) throws {
    guard let remoteUrl = download.remoteUrl else { throw DownloadProcessorError.invalidArguments }
    
    let downloadTask = session.downloadTask(with: remoteUrl)
    downloadTask.downloadId = download.id
    downloadTask.resume()
    
    currentDownloads.append(downloadTask)
    
    delegate.downloadProcessor(self, didStartDownloadWithId: download.id)
  }
  
  func pauseDownload(_ download: DownloadProcessorModel) throws {
    guard let downloadTask = currentDownloads.first(where: { $0.downloadId == download.id }) else { throw DownloadProcessorError.unknownDownload }
    
    downloadTask.suspend()
    
    delegate.downloadProcessor(self, didPauseDownloadWithId: download.id)
  }
  
  func resumeDownload(_ download: DownloadProcessorModel) throws {
    guard let downloadTask = currentDownloads.first(where: { $0.downloadId == download.id }) else { throw DownloadProcessorError.unknownDownload }
    
    downloadTask.resume()
    
    delegate.downloadProcessor(self, didResumeDownloadWithId: download.id)
  }
  
  func cancelDownload(_ download: DownloadProcessorModel) throws {
    guard let downloadTask = currentDownloads.first(where: { $0.downloadId == download.id }) else { throw DownloadProcessorError.unknownDownload }
    
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
  private func getDownloadTasksFromSession() -> [URLSessionDownloadTask] {
    var tasks = [URLSessionDownloadTask]()
    // Use a semaphore to make an async call synchronous
    // --There's no point in trying to complete instantiating this class without this list.
    let semaphore = DispatchSemaphore(value: 0)
    session.getTasksWithCompletionHandler { _, _, downloadTasks in
      tasks = downloadTasks
      semaphore.signal()
    }
    
    _ = semaphore.wait(timeout: .distantFuture)
    
    return tasks
  }
  
  private func populateDownloadListFromSession() {
    currentDownloads = self.getDownloadTasksFromSession()
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
    guard let downloadId = downloadTask.downloadId else { return }
    
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    // We want to call the progress update every 2%
    if let lastReportedProgress = throttleList[downloadId],
      abs(progress - lastReportedProgress) < 0.02 {
      // Less than a 2% change—it's a no-op
      return
    }

    // Update the throttle list and make the delegate call
    throttleList[downloadId] = progress
    delegate.downloadProcessor(self, downloadWithId: downloadId, didUpdateProgress: progress)
  }
  
  // Download completed—move the file to the appropriate place and update the DB
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let downloadId = downloadTask.downloadId,
      let delegate = delegate else { return }
    
    let download = delegate.downloadProcessor(self, downloadModelForDownloadWithId: downloadId)
    guard let localUrl = download?.localUrl else { return }
    
    let fileManager = FileManager.default
    do {
      try fileManager.moveItem(at: location, to: localUrl)
    } catch {
      delegate.downloadProcessor(self, downloadWithId: downloadId, didFailWithError: error)
    }
  }
  
  // Use this to handle and client-side download errors
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let downloadTask = task as? URLSessionDownloadTask, let downloadId = downloadTask.downloadId else { return }
    
    if let error = error as NSError? {
      let cancellationReason = (error.userInfo[NSURLErrorBackgroundTaskCancelledReasonKey] as? NSNumber)?.intValue
      if cancellationReason == NSURLErrorCancelledReasonUserForceQuitApplication || cancellationReason == NSURLErrorCancelledReasonBackgroundUpdatesDisabled {
        // The download was cancelled for technical reasons, but we might be able to restart it...
        var newTask: URLSessionDownloadTask?
        if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
          newTask = session.downloadTask(withResumeData: resumeData)
        } else {
          let download = delegate.downloadProcessor(self, downloadModelForDownloadWithId: downloadId)
          if let remoteUrl = download?.remoteUrl {
            newTask = session.downloadTask(with: remoteUrl)
          }
        }
        if let newTask = newTask {
          newTask.downloadId = downloadId
          newTask.resume()
          currentDownloads.append(newTask)
          delegate.downloadProcessor(self, didStartDownloadWithId: downloadId)
        }
        
        currentDownloads.removeAll { $0 == downloadTask }
      } else if error.code == NSURLErrorCancelled {
        // User-requested cancellation
        currentDownloads.removeAll { $0 == downloadTask }
        
        delegate.downloadProcessor(self, didCancelDownloadWithId: downloadId)
      } else {
        // Unknown error
        currentDownloads.removeAll { $0 == downloadTask }
        
        delegate.downloadProcessor(self, downloadWithId: downloadId, didFailWithError: error)
      }
    } else {
      // Success!
      currentDownloads.removeAll { $0 == downloadTask }
      
      delegate.downloadProcessor(self, didFinishDownloadWithId: downloadId)
    }
  }
}
