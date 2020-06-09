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

import Combine

protocol ObservablePrePostFactoObject: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
  // It's non-trivial to synthesise this, since it is a stored property. So let's not bother.
  var objectDidChange: ObservableObjectPublisher { get }
}

@propertyWrapper
struct PublishedPrePostFacto<Value: Equatable> {
  init(initialValue: Value) {
    self.init(wrappedValue: initialValue)
  }
  
  init(wrappedValue: Value) {
    value = wrappedValue
    publisher = CurrentValueSubject<Value, Never>(value)
  }
  
  private var value: Value
  private let publisher: CurrentValueSubject<Value, Never>!
  
  var projectedValue: AnyPublisher<Value, Never> {
    publisher.eraseToAnyPublisher()
  }
  
  var wrappedValue: Value {
    get { preconditionFailure("wrappedValue:get called") }
    set { preconditionFailure("wrappedValue:set called with \(newValue)") }
  }
  
  static subscript<EnclosingSelf: ObservablePrePostFactoObject>(
    _enclosingInstance object: EnclosingSelf,
    wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
    storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
  ) -> Value {
    get {
      object[keyPath: storageKeyPath].value
    }
    set {
      guard object[keyPath: storageKeyPath].value != newValue
      else { return }
      
      object.objectWillChange.send()
      object[keyPath: storageKeyPath].value = newValue
      object[keyPath: storageKeyPath].publisher.send(newValue)
      object.objectDidChange.send()
    }
  }
}
