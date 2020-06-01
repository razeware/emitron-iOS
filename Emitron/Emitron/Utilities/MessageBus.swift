// Copyright (c) 2020 Razeware LLC
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

import class Foundation.Timer
import Combine

struct Message {
  enum Level {
    case error, warning, success
  }
  
  let level: Level
  let message: String
  var autoDismiss: Bool = true
}

extension Message {
  var snackbarState: SnackbarState {
    SnackbarState(status: level.snackbarStatus, message: message)
  }
}

extension Message.Level {
  var snackbarStatus: SnackbarState.Status {
    switch self {
    case .error:
      return .error
    case .warning:
      return .warning
    case .success:
      return .success
    }
  }
}

final class MessageBus: ObservableObject {
  @Published private(set) var currentMessage: Message?
  @Published var messageVisible: Bool = false
  
  private var currentTimer: AnyCancellable?
  
  func post(message: Message) {
    invalidateTimer()
    
    currentMessage = message
    messageVisible = true
    
    if message.autoDismiss {
      currentTimer = createAndStartAutoDismissTimer()
    }
  }
  
  func dismiss() {
    invalidateTimer()
    self.messageVisible = false
  }
  
  private func createAndStartAutoDismissTimer() -> AnyCancellable {
    Timer
      .publish(every: Constants.autoDismissTime, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        guard let self = self else { return }
        
        self.messageVisible = false
        self.invalidateTimer()
      }
  }
  
  private func invalidateTimer() {
    currentTimer?.cancel()
    currentTimer = nil
  }
}
