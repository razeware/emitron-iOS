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
import CoreData
@testable import Emitron

struct CoreDataMocks {
  static func contents(context: NSManagedObjectContext) -> Contents {
    let contents = Contents(context: context)
    contents.name = "Sample Contents"
    contents.cardArtworkUrl = URL(string: "https://example.com/card_artwork.png")
    contents.contentType = "collection"
    contents.contributorString = "HELLO"
    contents.desc = "Description"
    contents.difficulty = "intermediate"
    contents.duration = 1234
    contents.id = 1
    contents.releasedAt = Date()
    contents.technologyTripleString = "Some Tech"
    contents.uri = "rw://betamax/collections/1"
    
    return contents
  }
  
  static func download(context: NSManagedObjectContext) -> Download {
    let download = Download(context: context)
    download.id = UUID()
    download.state = .pending
    download.fileName = "myVideo.mp4"
    
    return download
  }
}
