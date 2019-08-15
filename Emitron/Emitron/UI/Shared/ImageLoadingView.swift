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

import SwiftUI
import Combine

final class ImageLoader: ObservableObject {
  @Published private(set) var image: UIImage? = nil
  
  private let loadable: ImageLoadable
  private var cancellable: AnyCancellable?
  
  init(loadable: ImageLoadable) {
    self.loadable = loadable
  }
  
  deinit {
    cancellable?.cancel()
  }
  
  func load() {
    cancellable = loadable
      .loadImage()
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] image in
          self?.image = image
        }
    )
  }
  
  func cancel() {
    cancellable?.cancel()
  }
}

struct ImageLoadingView: View {
  @ObservedObject var imageLoader: ImageLoader
  
  init(image: ImageLoadable) {
    imageLoader = ImageLoader(loadable: image)
  }
  
  var body: some View {
    ZStack {
      if imageLoader.image != nil {
        Image(uiImage: imageLoader.image!)
          .resizable()
      }
    }
    .onAppear(perform: imageLoader.load)
    .onDisappear(perform: imageLoader.cancel)
  }
}

#if DEBUG
struct ImageLoadingView_Previews: PreviewProvider {
  static var previews: some View {
    let imageLoadable = #imageLiteral(resourceName: "myTutorialsGreen")
    return ImageLoadingView(image: imageLoadable)
  }
}
#endif
