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

private struct Layout {
  static let sidePadding: CGFloat = 18
  static let heightDivisor: CGFloat = 3
}

enum ContentScreen {
  case library, downloads, myTutorials, tips
  
  var titleMessage: String {
    switch self {
      // TODO: maybe this should be a func instead & we can pass in the actual search criteria here
    case .library: return "We couldn't find anything meeting the search criteria"
    case .downloads: return "You haven't downloaded any tutorials yet"
    case .myTutorials: return "You haven't started any tutorials yet"
    case .tips: return "Swipe left to delete a downloan"
    }
  }
  
  var detailMesage: String? {
    switch self {
    case .library: return "Try removing some filters"
    case .tips: return "Swipe on your downloads to remove them"
    default: return nil
    }
  }
  
  var buttonText: String? {
    switch self {
    case .downloads: return "Explore Tutorials"
    case .tips: return "Got it!"
    default: return nil
    }
  }
  
  var buttonIconName: String? {
    switch self {
    case .downloads, .tips: return "arrowGreen"
    case .myTutorials: return "arrowRed"
    default: return nil
    }
  }
  
  var buttonColor: Color? {
    switch self {
    case .downloads, .tips: return .appGreen
    case .myTutorials: return .copper
    default: return nil
    }
  }
}

struct ContentListView: View {
  
  @State var contentScreen: ContentScreen
  @State var isPresenting: Bool = false
  @State var contents: [ContentSummaryModel] = []
  var bgColor: Color
  @State var selectedMC: ContentSummaryMC?
  @EnvironmentObject var contentsMC: ContentsMC
  var callback: (()->())?
  var downloadsMC: DownloadsMC
  
  var body: some View {
    cardsTableView()
  }
  
  private func cardsTableView() -> AnyView {
    guard !self.contents.isEmpty else {
      let vStack = VStack {
        Spacer()
        createEmptyView()
        Spacer()
      }
      
      return AnyView(vStack)
    }
    
    let guardpost = Guardpost.current
    let user = guardpost.currentUser
    //TODO: This is a workaround hack to pass the MC the right partial content, because you can't do it in the "closure containing a declaration"
    
    let list = GeometryReader {  geometry in
      List {
        ForEach(self.contents, id: \.id) { partialContent in
          CardView(model: CardViewModel.transform(partialContent, cardViewType: .default)!, callback: {
            self.downloadsMC.saveDownload(with: partialContent.videoID, content: partialContent)
          }, contentScreen: self.contentScreen)
            .listRowBackground(self.bgColor)
            .background(self.bgColor)
            .onTapGesture {
              self.isPresenting = true
              self.selectedMC = ContentSummaryMC(guardpost: guardpost, partialContentDetail: partialContent)
          }
        }
        .onDelete(perform: self.delete)
        .frame(width: (geometry.size.width - (2 * Layout.sidePadding)), height: (geometry.size.height / Layout.heightDivisor), alignment: .center)
        
        Text("Should load more stuff...")
          // TODO: This is a hack to know when we've reached the end of the list, borrowed from
          // https://stackoverflow.com/questions/56602089/in-swiftui-where-are-the-control-events-i-e-scrollviewdidscroll-to-detect-the
          .onAppear { self.loadMoreContents() }
      }
      .sheet(isPresented: self.$isPresenting) {
        user != nil
          ? AnyView(ContentListingView(contentSummaryMC: self.selectedMC!, user: user!))
          : AnyView(Text("Unable to show video..."))
      }
    }
    
    return AnyView(list)
  }
  
  // TODO figure out how to return VStack instead
  private func createEmptyView() -> AnyView {
    let vStack = VStack {
      HStack {
        Spacer()
        
        Text(contentScreen.titleMessage)
        .font(.uiTitle2)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        
        Spacer()
      }
      
      addDetailText()
    }
    
    return AnyView(vStack)
  }
  
  // TODO return HStack
  private func addDetailText() -> AnyView? {
    guard let detail = contentScreen.detailMesage else { return nil }
    let stack = HStack {
        Spacer()
        
        Text(detail)
        .font(.uiHeadline)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        
        Spacer()
    }
    
    return AnyView(stack)
  }
  
  func loadMoreContents() {
    //TODO: Load more contents
    // contentsMC.loadContents()
  }
  
  func delete(at offsets: IndexSet) {
    contents.remove(atOffsets: offsets)
    callback?()
  }
}

#if DEBUG
struct ContentListView_Previews: PreviewProvider {

  static var previews: some View {
    let downloadsMC = DataManager.current.downloadsMC
    return ContentListView(contentScreen: .library, contents: [], bgColor: .paleGrey, downloadsMC: downloadsMC)
  }
}
#endif
