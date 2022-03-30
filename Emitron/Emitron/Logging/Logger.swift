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

struct Failure {
  static func login<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "login", reason: reason)
  }

  static func fetch<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "fetch", reason: reason)
  }

  static func loadFromPersistentStore<Source>(from source: Source.Type, reason: String) -> Self {
    loadFromPersistentStore(from: "\(Source.self)", reason: reason)
  }

  static func loadFromPersistentStore(from source: String, reason: String) -> Self {
    .init(source: source, action: "loadingFromPersistentStore", reason: reason)
  }

  static func saveToPersistentStore<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "savingToPersistentStore", reason: reason)
  }

  static func deleteFromPersistentStore<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "deleteToPersistentStore", reason: reason)
  }

  static func repositoryLoad<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "repositoryLoad", reason: reason)
  }

  static func unsupportedAction<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "unsupportedAction", reason: reason)
  }

  static func downloadAction<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "downloadAction", reason: reason)
  }

  static func viewModelAction<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "viewModelAction", reason: reason)
  }

  static func downloadService<Source>(from source: Source.Type, reason: String) -> Self {
    downloadService(from: "\(Source.self)", reason: reason)
  }

  static func downloadService(from source: String, reason: String) -> Self {
    .init(source: source, action: "downloadService", reason: reason)
  }

  static func appIcon<Source>(from source: Source.Type, reason: String) -> Self {
    .init(source: source, action: "appIcon", reason: reason)
  }

  private init<Source>(
    source: Source.Type,
    action: String,
    reason: String
  ) {
    self.init(
      source: "\(Source.self)",
      action: action,
      reason: reason
    )
  }

  private init(
    source: String,
    action: String,
    reason: String
  ) {
    self.source = source
    self.action = "Failed_\(action)"
    self.reason = reason
  }

  private let source: String
  private let action: String
  private let reason: String
  
  func log() {
    print(
      [ "source": source,
        "action": action,
        "reason": reason
      ]
    )
  }
}

struct Event {
  static func login<Source>(from source: Source.Type) -> Self {
    .init(
      source: "\(Source.self)",
      action: "Login"
    )
  }

  static func refresh<Source>(
    from source: Source.Type,
    action: String
  ) -> Self {
    .init(
      source: "\(Source.self)",
      action: "Login"
    )
  }

  static func syncEngine(action: String) -> Self {
    .init(
      source: "SyncEngine",
      action: action
    )
  }
  
  private let source: String
  private let action: String

  func log() {
    print("EVENT:: \(["source": source, "action": action])")
  }
}
