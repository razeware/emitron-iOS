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

import Foundation

// MARK: - internal
extension ContentSummaryState {
  var professional: Bool { content.professional }
  var free: Bool { content.free }
  var groupID: Int? { content.groupID }
}

// MARK: - ContentListDisplayable
extension ContentSummaryState: ContentListDisplayable {
  var id: Int { content.id }
  var name: String { content.name }

  var cardViewSubtitle: String {
    if domains.count == 1 {
      return domains.first!.name
    } else if domains.count > 1 {
      return "Multi-platform"
    }
    return ""
  }

  var descriptionPlainText: String {
    content.descriptionPlainText.replacingOccurrences(of: "\n", with: "")
  }

  var releasedAt: Date { content.releasedAt }
  var duration: Int { content.duration }

  var parentName: String? { parentContent?.name } // Proxied from Other Records

  var contentType: ContentType { content.contentType }
  var cardArtworkURL: URL? { content.cardArtworkURL }
  var ordinal: Int? { content.ordinal }
  var technologyTripleString: String { content.technologyTriple }
  var contentSummaryMetadataString: String { content.contentSummaryMetadataString }
  var contributorString: String { content.contributors }
  var videoIdentifier: Int? { content.videoIdentifier }
}
