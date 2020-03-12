// Copyright (c) 2019 Razeware LLC
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

import SwiftUI

private extension CGFloat {
  static let filterButtonSide: CGFloat = 27
  static let searchFilterPadding: CGFloat = 15
  static let filterSpacing: CGFloat = 6
  static let filtersPaddingTop: CGFloat = 12
}

struct LibraryView: View {
  @ObservedObject var filters: Filters
  @ObservedObject var libraryRepository: LibraryRepository
  @State var filtersPresented: Bool = false

  var body: some View {
    contentView
      .navigationBarTitle(
        Text(Constants.library)
      )
      .sheet(isPresented: $filtersPresented) {
        FiltersView(libraryRepository: self.libraryRepository, filters: self.filters)
          .background(Color.backgroundColor)
      }
  }
  
  private var contentControlsSection: some View {
    VStack {
      searchAndFilterControls
        .padding([.top], 15)
      
      if !libraryRepository.currentAppliedFilters.isEmpty {
        filtersView
          .padding([.top], 10)
      }
      numberAndSortView
        .padding([.vertical], 10)
    }
      .padding([.horizontal], .sidePadding)
      .background(Color.backgroundColor)
  }

  private var searchField: some View {
    SearchFieldView(searchString: filters.searchStr) { searchString in
      self.filters.searchStr = searchString
      self.updateFilters()
    }
  }

  private var searchAndFilterControls: some View {
    HStack {
      searchField
      
      Spacer()

      Button(action: {
        self.filtersPresented = true
      }, label: {
        Image("filter")
          .foregroundColor(.iconButton)
          .frame(width: .filterButtonSide, height: .filterButtonSide)
      })
        .accessibility(label: Text("Filter Library"))
        .padding([.horizontal], .searchFilterPadding)
    }
  }

  private var numberAndSortView: some View {
    HStack {
      Text("\(libraryRepository.totalContentNum) \(Constants.tutorials)")
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

        if self.filters.applied.count > 1 {
          AppliedFilterTagButton(name: Constants.clearAll, type: .destructive) {
            self.filters.removeAll()
            self.libraryRepository.filters = self.filters
          }
        }
        
        ForEach(self.filters.applied, id: \.self) { filter in
          AppliedFilterTagButton(name: filter.filterName, type: .default) {
            if filter.isSearch {
              self.filters.searchQuery = nil
            } else {
              filter.isOn.toggle()
              self.filters.all.update(with: filter)
            }
            self.filters.commitUpdates()
            self.libraryRepository.filters = self.filters
          }
        }
      }
        .padding([.horizontal], .sidePadding)
    }
      .padding([.horizontal], -.sidePadding)
  }

  private func updateFilters() {
    filters.searchQuery = filters.searchStr
    libraryRepository.filters = filters
  }

  private func changeSort() {
    filters.changeSortFilter()
    libraryRepository.filters = filters
  }

  private var contentView: some View {
    let header = AnyView(contentControlsSection)
    return ContentListView(
      contentRepository: libraryRepository,
      downloadAction: DownloadService.current,
      contentScreen: .library,
      headerView: header
    )
  }
}
