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
import Combine

// Manage a list of files to download—either queued, in progresss, paused or failed.
final class DownloadProcessor: NSObject {
  static let sessionIdentifier = "com.razeware.emitron.DownloadProcessor"
  
  class DownloadTask: Cancellable {
    private let urlSessionDownloadTask: URLSessionDownloadTask
    
    init(urlSessionDownloadTask: URLSessionDownloadTask) {
      self.urlSessionDownloadTask = urlSessionDownloadTask
    }
    
    func cancel() {
      urlSessionDownloadTask.cancel()
    }
    
    func pause() {
      urlSessionDownloadTask.suspend()
    }
    
    func resume() {
      urlSessionDownloadTask.resume()
    }
  }
  
  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: DownloadProcessor.sessionIdentifier)
    config.isDiscretionary = true
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: self, delegateQueue: .none)
  }()
  var backgroundSessionCompletionHandler: (() -> Void)?
  private var currentDownloads = [DownloadTask]()
}

extension DownloadProcessor {
  private func getDownloadTasksFromSession() -> [URLSessionDownloadTask] {
    var tasks = [URLSessionDownloadTask]()
    // Use a semaphore to make an async call synchronous
    // --There's no point in trying to complete instantiating this class without this list.
    let semaphore = DispatchSemaphore(value: 0)
    session.getTasksWithCompletionHandler { (_, _, downloadTasks) in
      tasks = downloadTasks
      semaphore.signal()
    }
    
    let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    
    return tasks
  }
  
  private func populateDownloadListFromSession() {
    let downloadTasks = self.getDownloadTasksFromSession()
    
    currentDownloads = downloadTasks.map { DownloadTask(urlSessionDownloadTask: $0) }
  }
}

extension DownloadProcessor: URLSessionDownloadDelegate {
  // When the background session has finished sending us events, we can tell the system we're done.
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    guard let backgroundSessionCompletionHandler = backgroundSessionCompletionHandler else { return }
    
    // Need to marshal back to the main queue
    DispatchQueue.main.async {
      backgroundSessionCompletionHandler()
    }
  }
  
  // Used to update the progress stats of a download task
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    // TODO
  }
  
  // Download completed—move the file to the appropriate place and update the DB
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    // TODO
  }
  
  // Use this to handle and client-side download errors
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    // TODO
  }
}

