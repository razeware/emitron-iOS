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
import Network

private struct Layout {
  static let buttonSize: CGFloat = 21
}

struct DownloadImageName {
  static let active: String = "downloadActive"
  static let inActive: String = "downloadInactive"
}

struct ContentSummaryView: View {
  
  @State var showHudView: Bool = false
  @State var showSuccess: Bool = false
  var callback: ((ContentDetailsModel, HudOption) -> Void)?
  @ObservedObject var downloadsMC: DownloadsMC
  @ObservedObject var contentDetailsVM: ContentDetailsVM
  private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
  
  var body: some View {
    let queue = DispatchQueue(label: "Monitor")
    monitor.start(queue: queue)
    return contentView
  }
  
  private var contentView: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(contentDetailsVM.data.technologyTripleString.uppercased())
          .font(.uiUppercase)
          .foregroundColor(.contentText)
          .kerning(0.5)
        // ISSUE: This isn't wrapping to multiple lines, not sure why yet, only .footnote and .caption seem to do it properly without setting a frame? Further investigaiton needed
        Spacer()
        
        if contentDetailsVM.data.professional {
          ProTag()
        }
      }
      .padding([.top], 20)
      
      Text(contentDetailsVM.data.name)
        .font(.uiTitle1)
        .lineLimit(nil)
        //.frame(idealHeight: .infinity) // ISSUE: This line is causing a crash
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 10)
        .foregroundColor(.titleText)
      
      Text(contentDetailsVM.data.contentSummaryMetadataString)
        .font(.uiCaption)
        .foregroundColor(.contentText)
        .lineSpacing(3)
        .padding([.top], 10)
      
      HStack(spacing: 30, content: {
        downloadButton
        bookmarkButton
        
        if contentDetailsVM.data.progression?.finished ?? false {
          CompletedTag()
        }
      })
        .padding([.top], 15)
      
      Text(contentDetailsVM.data.desc)
        .font(.uiCaption)
        .foregroundColor(.contentText)
        .lineSpacing(3)
        // ISSUE: Below line causes a crash, but somehow the UI renders the text into multiple lines, with the addition of
        // '.frame(idealHeight: .infinity)' to the TITLE...
        //.frame(idealHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 15)
        .lineLimit(nil)
      
      Text("By \(contentDetailsVM.data.contributorString)")
        .font(.uiFootnote)
        .foregroundColor(.contentText)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 10)
        .lineSpacing(3)
    }
  }
  
  private var downloadButton: some View {
    completeDownloadButton
      .onTapGesture {
        self.download()
    }
  }
  
  private var bookmarkButton: AnyView {
    //ISSUE: Changing this from button to "onTapGesture" because the tap target between the download button and thee
    //bookmark button somehow wasn't... clearly defined, so they'd both get pressed when the bookmark button got pressed
    
    let imageName = contentDetailsVM.data.bookmarked ? "bookmarkActive" : "bookmarkInactive"
    
    return AnyView(
      Image(imageName)
        .resizable()
        .frame(width: Layout.buttonSize, height: Layout.buttonSize)
        .onTapGesture {
          self.bookmark()
      }
    )
  }
  
  private var completeDownloadButton: some View {
    let image = Image(downloadImageName)
      .resizable()
      .frame(width: Layout.buttonSize, height: Layout.buttonSize)
      .onTapGesture {
        self.download()
    }
    
    switch downloadsMC.state {
      case .loading:
        
        if contentDetailsVM.data.isInCollection {
          
          guard let downloadedContent = downloadsMC.downloadedContent,
            downloadedContent.parentContent?.id == contentDetailsVM.data.id else {
              return AnyView(image)
          }
          
          return AnyView(CircularProgressBar(isCollection: true, progress: downloadsMC.collectionProgress))
          
        } else {
          // Only show progress on model that is currently being downloaded
          guard let downloadModel = downloadsMC.downloadData.first(where: { $0.content.id == contentDetailsVM.data.id }),
            downloadModel.content.id == downloadsMC.downloadedModel?.content.id else {
              return AnyView(image)
          }
          
          return AnyView(CircularProgressBar(isCollection: false, progress: downloadModel.downloadProgress))
      }
      
      default:
        return AnyView(image)
    }
  }
  
  private var downloadImageName: String {
    
    if contentDetailsVM.data.isInCollection {
      return downloadsMC.data.contains { downloadModel in
        return downloadModel.id == contentDetailsVM.data.id
        } ? DownloadImageName.inActive : DownloadImageName.active
    } else {
      return downloadsMC.data.contains(where: { $0.id == contentDetailsVM.data.id }) ? DownloadImageName.inActive : DownloadImageName.active
    }
  }
  
  private func download() {
    if UserDefaults.standard.wifiOnlyDownloads && monitor.currentPath.status != .satisfied {
      callback?(contentDetailsVM.data, .notOnWifi)
    } else {
      let success = downloadImageName != DownloadImageName.inActive
      let hudOption: HudOption = success ? .success : .error
      callback?(contentDetailsVM.data, hudOption)
    }
  }
  
  private func bookmark() {
    contentDetailsVM.toggleBookmark()
  }
}
