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

public extension Optional {
  /// Represents that an `Optional` was `nil`.
  enum UnwrapError: Error {
    case `nil`
    case typeMismatch
  }

  /// [An alternative to overloading `??` to throw errors upon `nil`.](
  /// https://forums.swift.org/t/unwrap-or-throw-make-the-safe-choice-easier/14453/7)
  /// - Note: Useful for emulating `break`, with `map`, `forEach`, etc.
  /// - Throws: `UnwrapError` when `nil`.
  var unwrapped: Wrapped {
    get throws {
      switch self {
      case let wrapped?:
        return wrapped
      case nil:
        throw UnwrapError.nil
      }
    }
  }

  /// [An alternative to overloading `??` to throw errors upon `nil`.](
  /// https://forums.swift.org/t/unwrap-or-throw-make-the-safe-choice-easier/14453/7)
  /// - Note: Useful for emulating `break`, with `map`, `forEach`, etc.
  /// - Throws: `UnwrapError`
  func unwrap<Wrapped>() throws -> Wrapped {
    switch self {
    case let wrapped as Wrapped:
      return wrapped
    case .some:
      throw UnwrapError.typeMismatch
    case nil:
      throw UnwrapError.nil
    }
  }
}
