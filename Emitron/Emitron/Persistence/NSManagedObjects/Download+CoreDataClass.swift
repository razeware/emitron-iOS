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
    case enqueued
    case inProgress
    case paused
    case cancelled
    case failed
    case complete
    case error
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
