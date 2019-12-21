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
import SwiftUI
import Combine
import SwiftyJSON

enum DownloadsAction {
  case save, delete, cancel
}

// Conforming to NSObject so that we can conform to URLSessionDownloadDelegate
class DownloadsMC: NSObject, ObservableObject, ContentPaginatable {

  // MARK: - ContentPaginatable
  var currentPage: Int = 0 // NOT IN USE
  var isLoadingMore: Bool = false // NOT IN USE
  
  func loadMore() { } // NOT IN USE
  func reload() { } // NOT IN USE

  // MARK: - Public Properties
  var downloadedContent: ContentDetailsModel? {
    willSet {
      objectWillChange.send(())
    }
  }
  

  // MARK: - Private Properties
  private let user: UserModel
  private let videosMC: VideosMC
  
  private(set) var objectWillChange = PassthroughSubject<Void, Never>()
  private(set) var state = DataState.initial {
    willSet {
      objectWillChange.send(())
    }
  }
  private let downloadService: DownloadService
  
  // TODO: Get rid of this
  var isEpisodeOnly: Bool = false
  var callback: (Bool) -> () = { _ in }
  var collectionProgress: CGFloat = 0
  var downloadedModel: DownloadModel?

  let contentScreen: ContentScreen = .downloads
  
  // ISSUE: Probably don't re-compute this all the time...
  var data: [ContentListDisplayable] {
    let downloadedContents = downloadData.map { $0.content }.filter { model -> Bool in
      let isNotEpisode = model.contentType != .episode
      // Only allow episodes in ContentDetailData if the parent hasn't also been downloaded
      let isEpisodeWithoutParent = !downloadData.contains(where: { $0.content.id == model.parentContentId } )
      return isNotEpisode || isEpisodeWithoutParent
    }    
    return downloadedContents
  }
  
  var totalContentNum: Int {
    return data.count
  }
  
  private(set) var downloadData: [DownloadModel] = []

  // MARK: - Initializers
  init(user: UserModel, downloadService: DownloadService) {
    self.user = user
    self.videosMC = VideosMC(user: self.user)
    self.downloadService = downloadService
		super.init()
  }
  
  func deleteDownload(with: ContentDetailsModel) {
    // TODO
  }
  
  func cancelDownload(with: ContentDetailsModel, isEpisodeOnly: Bool) {
    // TODO
  }
  
  func saveDownload(with: ContentDetailsModel, isEpisodeOnly: Bool) {
    // TODO
  }
  
  func saveCollection(with: ContentDetailsModel, isEpisodeOnly: Bool) {
    // TODO
  }
  
  func deleteCollectionContents(withParent parent: ContentDetailsModel, showCallback: Bool) {
    // TODO
  }
}
