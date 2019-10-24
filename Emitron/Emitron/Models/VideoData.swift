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

class VideoData: NSObject, NSCoding {
  var url: URL?
  var data: Data?
  var content: ContentDetailsModel?
  
  init(url: URL? = nil) {
    self.url = url
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(1, forKey: .versionKey)
    guard let videoURL = url, let savedContent = content else { return }
    
    let contentsData = ContentsData(id: savedContent.id, name: savedContent.name, uri: savedContent.uri, description: savedContent.description, releasedAt: savedContent.releasedAt, free: savedContent.free, duration: savedContent.duration, popularity: savedContent.popularity, bookmarked: savedContent.bookmarked, cardArtworkURL: savedContent.cardArtworkURL, technologyTripleString: savedContent.technologyTripleString, contributorString: savedContent.contributorString, videoID: savedContent.videoID, index: savedContent.index, professional: savedContent.professional, difficulty: savedContent.difficulty.rawValue, contentType: savedContent.contentType.rawValue, parentContentId: savedContent.parentContentId)
    
    print("videoURL: \(videoURL)")
    aCoder.encode(videoURL.absoluteString, forKey: .videoKey)
    aCoder.encode(data)
    aCoder.encode(contentsData, forKey: .contentKey)
  }
  
  required init?(coder aDecoder: NSCoder) {
    aDecoder.decodeInteger(forKey: .versionKey)
    if let videoURL = aDecoder.decodeObject(forKey: .videoKey) as? String {
      self.url = URL(string: videoURL)
      
      self.data = try? Data(contentsOf: self.url!)
      
      print("data???: \(try? Data(contentsOf: self.url!))")
    }
    
    if let data = aDecoder.decodeData() {
      print("data: \(data) & videoURL: \(url)")
//      self.data = data
      
    }
    
    if let content = aDecoder.decodeObject(forKey: .contentKey) as? ContentsData {
      self.content = ContentDetailsModel(content)
    }
  }
}
