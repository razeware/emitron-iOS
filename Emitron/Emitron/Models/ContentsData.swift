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

extension String {
  static let contentIdKey: String = "Content.id"
  static let contentNameKey: String = "Content.name"
  static let contentUriKey: String = "Content.uri"
  static let contentDescriptionKey: String = "Content.contentDescription"
  static let contentReleasedAtKey: String = "Content.releasedAt"
  static let contentFreeKey: String = "Content.free"
  static let contentDurationKey: String = "Content.duration"
  static let contentPopularityKey: String = "Content.popularity"
  static let contentBookmarkedKey: String = "Content.bookmarked"
  static let contentCardArtworkURLKey: String = "Content.cardArtworkURL"
  static let contentTechnologyTripleStringKey: String = "Content.technologyTripleString"
  static let contentContributorStringKey: String = "Content.contributorString"
  static let contentVideoIDKey: String = "Content.videoID"
  static let contentIndexKey: String = "Content.index"
  static let contentProfessionalKey: String = "Content.professional"
}

class ContentsData: NSObject, NSCoding {
  var id: Int = 0
  var name: String  = ""
  var uri: String  = ""
  var contentDescription: String = ""
  var releasedAt: Date = Date()
  var free: Bool = false
  var duration: Int = 0
  var popularity: Double = 0.0
  var bookmarked: Bool = false
  var cardArtworkURL: URL?
  var technologyTripleString: String = ""
  var contributorString: String = ""
  var videoID: Int?
  var index: Int?
  var professional: Bool = false
  
  init(id: Int, name: String, uri: String, description: String, releasedAt: Date, free: Bool, duration: Int, popularity: Double, bookmarked: Bool, cardArtworkURL: URL?, technologyTripleString: String, contributorString: String, videoID: Int?, index: Int?, professional: Bool) {
    self.id = id
    self.name = name
    self.uri = uri
    self.contentDescription = description
    self.releasedAt = releasedAt
    self.free = free
    self.duration = duration
    self.popularity = popularity
    self.bookmarked = bookmarked
    self.cardArtworkURL = cardArtworkURL
    self.technologyTripleString = technologyTripleString
    self.contributorString = contributorString
    self.videoID = videoID
    self.index = index
    self.professional = professional
    super.init()
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(1, forKey: .versionKey)
    aCoder.encode(id, forKey: .contentIdKey)
    aCoder.encode(name, forKey: .contentNameKey)
    aCoder.encode(uri, forKey: .contentUriKey)
    aCoder.encode(contentDescription, forKey: .contentDescriptionKey)
    aCoder.encode(releasedAt, forKey: .contentReleasedAtKey)
    aCoder.encode(free, forKey: .contentFreeKey)
    aCoder.encode(duration, forKey: .contentDurationKey)
    aCoder.encode(bookmarked, forKey: .contentBookmarkedKey)
    aCoder.encode(technologyTripleString, forKey: .contentTechnologyTripleStringKey)
    aCoder.encode(contributorString, forKey: .contentContributorStringKey)
    aCoder.encode(professional, forKey: .contentProfessionalKey)
    
    if let cardArtworkURL = cardArtworkURL {
      aCoder.encode(cardArtworkURL, forKey: .contentCardArtworkURLKey)
    }
    
    if let videoID = videoID {
      aCoder.encode(videoID, forKey: .contentVideoIDKey)
    }
    
    if let index = index {
      aCoder.encode(index, forKey: .contentIndexKey)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init()
    aDecoder.decodeInteger(forKey: .versionKey)
    
    if let id = aDecoder.decodeObject(forKey: .contentIdKey) as? Int {
      self.id = id
    }
    
    if let name = aDecoder.decodeObject(forKey: .contentNameKey) as? String {
      self.name = name
    }
    
    if let uri = aDecoder.decodeObject(forKey: .contentUriKey) as? String {
      self.uri = uri
    }
    
    if let contentDescription = aDecoder.decodeObject(forKey: .contentDescriptionKey) as? String {
      self.contentDescription = contentDescription
    }
    
    if let contentDescription = aDecoder.decodeObject(forKey: .contentDescriptionKey) as? String {
      self.contentDescription = contentDescription
    }
    
    if let releasedAt = aDecoder.decodeObject(forKey: .contentDurationKey) as? Date {
      self.releasedAt = releasedAt
    }
    
    if let free = aDecoder.decodeObject(forKey: .contentFreeKey) as? Bool {
      self.free = free
    }
    
    if let duration = aDecoder.decodeObject(forKey: .contentDurationKey) as? Int {
      self.duration = duration
    }
    
    if let bookmarked = aDecoder.decodeObject(forKey: .contentBookmarkedKey) as? Bool {
      self.bookmarked = bookmarked
    }
    
    if let cardArtworkURL = aDecoder.decodeObject(forKey: .contentCardArtworkURLKey) as? URL {
      self.cardArtworkURL = cardArtworkURL
    }
    
    if let technologyTripleString = aDecoder.decodeObject(forKey: .contentTechnologyTripleStringKey) as? String {
      self.technologyTripleString = technologyTripleString
    }
    
    if let contributorString = aDecoder.decodeObject(forKey: .contentContributorStringKey) as? String {
      self.contributorString = contributorString
    }
    
    if let index = aDecoder.decodeObject(forKey: .contentIndexKey) as? Int {
      self.index = index
    }
    
    if let professional = aDecoder.decodeObject(forKey: .contentProfessionalKey) as? Bool {
      self.professional = professional
    }
  }
}
