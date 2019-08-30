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
}

struct ContentListView: View {
  
  @State var isPresenting: Bool = false
  var contents: [ContentSummaryModel] = []
  var bgColor: Color
  @State var selectedMC: ContentSummaryMC?
  @EnvironmentObject var contentsMC: ContentsMC
  @State var imageLoaded: Bool = false
  
  var body: some View {
    //TODO: Currently showing this as a scrollview, so that the tab bar navigation doesn't cause a crash
    // because apparently using a List causes a crash...  in the tab bar navigation...
//    NavigationView {
//      cardTableViewWithNav()
//    }
    //cardsTableView()
     cardsScrollView()
  }
  
  private func cardsScrollView() -> AnyView {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser
    //TODO: This is a workaround hack to pass the MC the right partial content, because you can't do it in the "closure containing a declaration"
    
    let scrollView = ScrollView(.vertical, showsIndicators: false) {
      ForEach(contents, id: \.id) { partialContent in
        CardView(model: CardViewModel.transform(partialContent, cardViewType: .default)!)
        .listRowBackground(self.bgColor)
        .background(self.bgColor)
        .onTapGesture {
          self.imageLoaded = false
          self.isPresenting = true
          self.selectedMC = ContentSummaryMC(guardpost: guardpost, partialContentDetail: partialContent)
        }
      }
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
      .padding([.leading, .trailing], Layout.sidePadding)
    return AnyView(scrollView)
  }
  
  private func cardsTableView() -> AnyView {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser
    //TODO: This is a workaround hack to pass the MC the right partial content, because you can't do it in the "closure containing a declaration"
    
    let list = List {
      ForEach(contents, id: \.id) { partialContent in
        CardView(model: CardViewModel.transform(partialContent, cardViewType: .default)!)
          .listRowBackground(self.bgColor)
          .background(self.bgColor)
          .onTapGesture {
            self.isPresenting = true
            self.selectedMC = ContentSummaryMC(guardpost: guardpost, partialContentDetail: partialContent)
          }
      }
      Text("Should load more stuff...")
        // TODO: This is a hack to know when we've reached the end of the list, borrowed from
        // https://stackoverflow.com/questions/56602089/in-swiftui-where-are-the-control-events-i-e-scrollviewdidscroll-to-detect-the
        .onAppear {
          self.loadMoreContents()
        }
    }
        .sheet(isPresented: self.$isPresenting) {
          user != nil
            ? AnyView(ContentListingView(contentSummaryMC: self.selectedMC!, user: user!))
            : AnyView(Text("Unable to show video..."))
        }
    
    return AnyView(list)
  }
  
//  func cardTableViewWithNav() -> AnyView {
//    let guardpost = Guardpost.current
//    let user = guardpost.currentUser
//    //TODO: This is a workaround hack to pass the MC the right partial content, because you can't do it in the "closure containing a declaration"
//    
//    let list = List {
//      ForEach(contents, id: \.id) { partialContent in
//        NavigationLink(destination: ContentListingView(contentDetailsMC: ContentDetailsMC(guardpost: guardpost, partialContentDetail: partialContent), imageLoaded: self.$imageLoaded, user: user!)) {
//          CardView(model: CardViewModel.transform(partialContent, cardViewType: .default)!)
//          .listRowBackground(self.bgColor)
//          .background(self.bgColor)
//        }
//      }
//      Text("Should load more stuff...")
//        // TODO: This is a hack to know when we've reached the end of the list, borrowed from
//        // https://stackoverflow.com/questions/56602089/in-swiftui-where-are-the-control-events-i-e-scrollviewdidscroll-to-detect-the
//        .onAppear {
//          self.loadMoreContents()
//        }
//    }
//    
//    return AnyView(list)
//  }
  
  func loadMoreContents() {
    //TODO: Load more contents
    contentsMC.loadMore()
  }
}

#if DEBUG
struct ContentListView_Previews: PreviewProvider {

  static var previews: some View {
    ContentListView(contents: [], bgColor: .paleGrey)
  }
}
#endif
