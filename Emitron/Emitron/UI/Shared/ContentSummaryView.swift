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

struct ContentSummaryView: View {
  
  @EnvironmentObject var downloadsMC: DownloadsMC
  var details: ContentSummaryModel
  var body: some View {
    VStack(alignment: .leading) {
      
      Text(details.technologyTripleString.uppercased())
        .font(.uiUppercase)
        .foregroundColor(.coolGrey)
        .kerning(0.5)
      // ISSUE: This isn't wrapping to multiple lines, not sure why yet, only .footnote and .caption seem to do it properly without setting a frame? Further investigaiton needed
      
      Text(details.name) // TITLE
        .font(.uiTitle1)
        .lineLimit(nil)
        //.frame(idealHeight: .infinity) // ISSUE: This line is causing a crash
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        .padding([.top], -5)
      
      Text(details.dateAndTimeString)
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
      
      HStack {
        Button(action: {
          // Download Action
          self.download()
        }) {
          Image("downloadInactive")
            .padding([.trailing], 30)
            .foregroundColor(.coolGrey)
        }
        
        Button(action: {
          // Bookmark Action
          self.bookmark()
        }) {
          Image("bookmarkInactive")
            .resizable()
            .frame(maxWidth: 20, maxHeight: 20)
            .foregroundColor(.coolGrey)
        }
      }
      .padding([.top], 20)
      
      Text(details.description)
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
        .lineLimit(nil)
        // ISSUE: Below line causes a crash, but somehow the UI renders the text into multiple lines, with the addition of
        // '.frame(idealHeight: .infinity)' to the TITLE...
        //.frame(idealHeight: .infinity)
        .padding([.top], 20)
      
      Text("By \(details.contributorString)")
        .font(.uiFootnote)
        .foregroundColor(.coolGrey)
        .lineLimit(2)
        .padding([.top], 5)
    }
  }
  
  private func download() {
    downloadsMC.saveDownload(with: details.videoID, content: details)
  }
  
  private func bookmark() { }
}

#if DEBUG
struct ContentSummaryView_Previews: PreviewProvider {
    static var previews: some View {
      let downloadsMC = DataManager.current.downloadsMC
      return ContentSummaryView(details: ContentSummaryModel.test).environmentObject(downloadsMC)
    }
}
#endif
