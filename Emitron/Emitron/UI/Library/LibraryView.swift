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
  static let searchFilterPadding: CGFloat = 30
  static let filterSpacing: CGFloat = 6
  static let filtersPaddingTop: CGFloat = 12
}

struct LibraryView: View {

  @EnvironmentObject var contentsMC: ContentsMC
  var downloadsMC: DownloadsMC
  @EnvironmentObject var filters: Filters
  @State var filtersPresented: Bool = false
  @State private var searchText = ""
  @State var showHudView: Bool = false
  @State var hudOption: HudOption = .success

  var body: some View {
    contentView
      .navigationBarTitle(
        Text(Constants.library))
      .navigationBarItems(trailing:
        Group {
          Button(action: {
            self.contentsMC.reloadContents()
          }) {
            Image(systemName: "arrow.clockwise")
              .foregroundColor(.iconButton)
          }
      })
      .sheet(isPresented: $filtersPresented) {
        FiltersView().environmentObject(self.filters).environmentObject(self.contentsMC)
      .background(Color.backgroundColor)
    }
    .hud(isShowing: $showHudView, hudOption: $hudOption) {
      self.showHudView = false
    }
  }

  private var contentControlsSection: some View {
    VStack {
      searchAndFilterControls
        .padding([.top], 15)
      
      if !filters.applied.isEmpty {
        filtersView
          .padding([.top], 10)
      }
      numberAndSortView
        .padding([.top, .bottom], 10)
    }
    .padding([.leading, .trailing], 20)
    .background(Color.backgroundColor)
    .shadow(color: Color.shadowColor, radius: 1, x: 0, y: 2)
  }

  private var searchField: some View {
    //TODO: Need to figure out how to erase the textField

    TextField(Constants.search,
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
  }

  private var searchAndFilterControls: some View {
    HStack {
      searchField

      Button(action: {
        self.filtersPresented = true
      }, label: {
        Image("filter")
          .foregroundColor(.iconButton)
          .frame(width: .filterButtonSide, height: .filterButtonSide)
      })
        .padding([.leading], .searchFilterPadding)
    }
  }

  private var numberAndSortView: some View {
    HStack {
      Text("\(contentsMC.numTutorials) \(Constants.tutorials)")
        .font(.uiLabelBold)
        .foregroundColor(.contentText)

      Spacer()

      Button(action: {
        // Change sort
        self.changeSort()
      }) {
        HStack {
          Image("sort")
            .foregroundColor(.textButtonText)

          Text(filters.sortFilter.name)
            .font(.uiLabelBold)
            .foregroundColor(.textButtonText)
        }
      }
    }
  }

  private var filtersView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
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
  }

  private func updateFilters() {
    filters.searchQuery = self.searchText
    contentsMC.updateFilters(newFilters: filters)
  }

  private func changeSort() {
    filters.changeSortFilter()
    contentsMC.updateFilters(newFilters: filters)
  }

  private var contentView: AnyView {
    let header = AnyView(contentControlsSection)
    let contentSectionView = ContentListView(downloadsMC: self.downloadsMC, contentScreen: .library, contents: contentsMC.data, headerView: header, dataState: contentsMC.state, totalContentNum: contentsMC.numTutorials) { (action, content) in
      switch action {
        case .delete:
          if let videoID = content.videoID {
            self.delete(for: videoID)
          }
        case .save:
          self.save(for: content)
        }
      }

    return AnyView(contentSectionView)
  }

  private func delete(for videoId: Int) {
    downloadsMC.deleteDownload(with: videoId)
    self.downloadsMC.callback = { success in
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = success ? .success : .error
      self.showHudView = true
    }
  }

  private func save(for content: ContentDetailsModel) {
    guard downloadsMC.state != .loading else {
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = .error
      self.showHudView = true
      return
    }

    guard !downloadsMC.data.contains(where: { $0.content.id == content.id }) else {
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = .error
      self.showHudView = true
      return
    }

    if content.isInCollection {
      
      if content.groups.isEmpty {
        self.contentsMC.getContentSummary(with: content.id) { detailsModel in
          self.downloadsMC.saveCollection(with: detailsModel)
        }
      }
    } else {
      self.downloadsMC.saveDownload(with: content)
    }
    
    self.downloadsMC.callback = { success in
      if self.showHudView {
        // dismiss hud currently showing
        self.showHudView.toggle()
      }

      self.hudOption = success ? .success : .error
      self.showHudView = true
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
          .foregroundColor(.iconButton)
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
    return LibraryView(downloadsMC: downloadsMC).environmentObject(filters).environmentObject(contentsMC)
  }
}
#endif
