/*
 * Copyright (c) 2019 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import CoreData

@objc(Download)
public class Download: NSManagedObject {
  enum State: Int16 {
    case pending = 0
    case urlRequested
    case readyForDownload
    case enqueued
    case inProgress
    case paused
    case cancelled
    case failed
    case complete
    case error
  }
  
  static func findBy(state: State) -> NSFetchRequest<Download> {
    let request: NSFetchRequest<Download> = fetchRequest()
    let predicate = NSPredicate(format: "stateInt = %d", state.rawValue)
    request.predicate = predicate
    let sortDescriptor = NSSortDescriptor(key: "dateRequested", ascending: true)
    request.sortDescriptors = [sortDescriptor]
    return request
  }
  
  static func downloadQueue(size queueSize: Int? = .none) -> NSFetchRequest<Download> {
    let request: NSFetchRequest<Download> = Download.fetchRequest()
    // Want either in-progress or enqueued
    let predicate = NSPredicate(format: "stateInt = %d OR stateInt = %d", Download.State.enqueued.rawValue, Download.State.inProgress.rawValue)
    request.predicate = predicate
    // Make sure the in-progress ones appear first
    request.sortDescriptors = [
      NSSortDescriptor(key: "stateInt", ascending: Download.State.inProgress.rawValue < Download.State.enqueued.rawValue),
      NSSortDescriptor(key: "dateRequested", ascending: true)
    ]
    if let queueSize = queueSize {
      request.fetchLimit = queueSize
      request.fetchBatchSize = queueSize
      request.fetchOffset = 0
    }
    return request
  }
  
  var state: State {
    get { return State(rawValue: self.stateInt) ?? .pending }
    set { self.stateInt = newValue.rawValue }
  }
  
  func assignDefaults() {
    dateRequested = Date()
    lastValidated = nil
    localUrl = nil
    progress = 0
    remoteUrl = nil
    state = .pending
    id = UUID()
    fileName = nil
    content = nil
  }
}
