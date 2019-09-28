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

// https://mecid.github.io/2019/06/12/understanding-property-wrappers-in-swiftui/

import SwiftUI

private extension CGFloat {
  static let filterButtonSide: CGFloat = 27
  static let sidePadding: CGFloat = 18
  static let searchFilterPadding: CGFloat = 42
  static let filterSpacing: CGFloat = 6
  static let filtersPaddingTop: CGFloat = 12
}

struct LibraryView: View {

  @EnvironmentObject var contentsMC: ContentsMC
  @EnvironmentObject var downloadsMC: DownloadsMC
  @EnvironmentObject var filters: Filters
  @State var filtersPresented: Bool = false
  @State private var searchText = ""
  @State var showHudView: Bool = false
  @State var showSuccess: Bool = false

  var body: some View {
    
    ZStack(alignment: .bottom) {
      createVStack()
      
      if showHudView {
        createHudView()
        .animation(.spring())
      }
    }
  }

  private func createVStack() -> some View {
    let vStack = VStack {
      VStack {

        HStack {
          searchField()

          Button(action: {
            self.filtersPresented.toggle()
          }, label: {
            Image("filter")
              .foregroundColor(.battleshipGrey)
              .frame(width: .filterButtonSide, height: .filterButtonSide)
              .sheet(isPresented: self.$filtersPresented) {
                FiltersView(isPresented: self.$filtersPresented).environmentObject(self.filters).environmentObject(self.contentsMC)
              }
          })
            .padding([.leading], .searchFilterPadding)
        }

        HStack {
          Text("\(contentsMC.numTutorials) \(Constants.tutorials)")
            .font(.uiLabel)
            .foregroundColor(.battleshipGrey)
          
          Spacer()

          Button(action: {
            // Change sort
            self.changeSort()
          }) {
            HStack {
              Image("sort")
                .foregroundColor(.battleshipGrey)

              Text(filters.sortFilter.name)
                .font(.uiLabel)
                .foregroundColor(.battleshipGrey)
            }
          }
        }
        .padding([.top], .sidePadding)

        if !filters.applied.isEmpty {
          filtersView()
        }
      }
      .padding([.leading, .trailing, .top], .sidePadding)

      contentView()
        .padding([.top], .sidePadding)
        .background(Color.paleGrey)
    }
    .background(Color.paleGrey)
    
    return AnyView(vStack)
  }
  
  private func createHudView() -> some View {
    let option: HudOption = showSuccess ? .success : .error
    return HudView(option: option) {
      self.showHudView = false
    }
  }
  
  private func filtersView() -> AnyView {
    let view = ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: .filterSpacing) {

        AppliedFilterView(filter: nil, type: .destructive, name: Constants.clearAll) {
          self.contentsMC.updateFilters(newFilters: self.filters)
        }
        .environmentObject(self.filters)

        ForEach(filters.applied, id: \.self) { filter in
          AppliedFilterView(filter: filter, type: .default) {
            self.contentsMC.updateFilters(newFilters: self.filters)
          }
          .environmentObject(self.filters)
        }
      }
    }
    .padding([.top], .filtersPaddingTop)

    return AnyView(view)
  }

  private func searchField() -> AnyView {
    //TODO: Need to figure out how to erase the textField
    
    let searchField = TextField(Constants.search,
                                text: $searchText,
                                onEditingChanged: { _ in
      print("Editing changed:  \(self.searchText)")
    }, onCommit: { () in
      UIApplication.shared.keyWindow?.endEditing(true)
      self.updateFilters()
    })
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .modifier(ClearButton(text: $searchText, action: {
        UIApplication.shared.keyWindow?.endEditing(true)
        self.updateFilters()
      }))

    return AnyView(searchField)
  }

  private func updateFilters() {
    filters.searchQuery = self.searchText
    contentsMC.updateFilters(newFilters: filters)
  }

  private func changeSort() {
    filters.changeSortFilter()
    contentsMC.updateFilters(newFilters: filters)
  }

  private func contentView() -> AnyView {
    switch contentsMC.state {
    case .initial,
         .loading where contentsMC.data.isEmpty:
      return AnyView(Text(Constants.loading))
    case .failed:
      return AnyView(Text("Error"))
    case .hasData,
         .loading where !contentsMC.data.isEmpty:
      //      let sorted = sortSelection.sorted(data: contentsMC.data)
      //      let parameters = filters.applied
      //      let filtered = sorted.filter { $0.domains.map { $0.id }.contains(domainIdInt) }
      //

      var updatedContents = contentsMC.data
      var contentListView = ContentListView(contentScreen: .library, contents: contentsMC.data, bgColor: .paleGrey) { (action, content) in
        switch action {
        case .delete:
          self.downloadsMC.deleteDownload(with: content.videoID) { (success, contents) in
            if self.showHudView {
              // dismiss hud currently showing
              self.showHudView.toggle()
            }
            
            self.showSuccess = success
            self.showHudView = true
            if success {
              DispatchQueue.main.async {
                updatedContents = contents
              }
            }
          }

        case .save:
          self.downloadsMC.saveDownload(with: content) { (success, contents) in
            if self.showHudView {
              // dismiss hud currently showing
              self.showHudView.toggle()
            }
            
             self.showSuccess = success
             self.showHudView = true
            if success {
              DispatchQueue.main.async {
                updatedContents = contents
              }
            }
          }
        }
      }

      downloadsMC.setDownloads(for: updatedContents) { contents in
        DispatchQueue.main.async {
          contentListView.updateContents(with: contents)
        }
      }

      return AnyView(contentListView)
    default:
      return AnyView(Text("Default View"))
    }
  }
}

// Inspired by: https://forums.developer.apple.com/thread/121162
struct ClearButton: ViewModifier {
  @Binding var text: String
  var action: () -> Void

  public func body(content: Content) -> some View {
    HStack {
      content
      Button(action: {
        self.text = ""
        self.action()
      }) {
        Image(systemName: "multiply.circle.fill")
          // If we don't enforce a frame, the button doesn't register the tap action
          .frame(width: 25, height: 25, alignment: .center)
          .foregroundColor(.secondary)
      }
    }
  }
}

#if DEBUG
struct LibraryView_Previews: PreviewProvider {
  static var previews: some View {
    guard let dataManager = DataManager.current else { fatalError("dataManager is nil in LibraryView") }
    let contentsMC = dataManager.contentsMC
    let downloadsMC = dataManager.downloadsMC
    let filters = dataManager.filters
    return LibraryView().environmentObject(filters).environmentObject(contentsMC).environmentObject(downloadsMC)
  }
}
#endif
