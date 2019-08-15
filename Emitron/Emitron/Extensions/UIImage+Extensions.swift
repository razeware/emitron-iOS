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

// Inspiration from: https://osinski.dev/posts/swiftui-image-loading/

import UIKit
import Combine
import SwiftUI

protocol ImageLoadable {
  func loadImage() -> AnyPublisher<UIImage, Error>
  func equals(_ other: ImageLoadable) -> Bool
}

extension ImageLoadable where Self: Equatable {
    func equals(_ other: ImageLoadable) -> Bool {
        return other as? Self == self
    }
}

struct AnyImageLoadable: ImageLoadable, Equatable {
    private let loadable: ImageLoadable
    
    init(_ loadable: ImageLoadable) {
        self.loadable = loadable
    }
    
    func loadImage() -> AnyPublisher<UIImage, Error> {
        return loadable.loadImage()
    }
    
    static func ==(lhs: AnyImageLoadable, rhs: AnyImageLoadable) -> Bool {
        return lhs.loadable.equals(rhs.loadable)
    }
}

extension URL: ImageLoadable {
  enum ImageLoadingError: Error {
    case incorrectData
  }
  
  func loadImage() -> AnyPublisher<UIImage, Error> {
    URLSession
      .shared
      .dataTaskPublisher(for: self)
      .tryMap { data, _ in
        guard let image = UIImage(data: data) else {
          throw ImageLoadingError.incorrectData
        }
        
        return image
    }
    .eraseToAnyPublisher()
  }
}

extension UIImage: ImageLoadable {
  func loadImage() -> AnyPublisher<UIImage, Error> {
    return Just(self)
      // Just's Failure type is Never
      // Our protocol expect's it to be Error, so we need to `override` it
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
}
