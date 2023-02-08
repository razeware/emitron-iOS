// Copyright (c) 2022 Kodeco Inc

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

struct LibraryView: View {
  @EnvironmentObject private var downloadService: DownloadService
  @ObservedObject private var filters: Filters
  @ObservedObject private var libraryRepository: LibraryRepository
  @State private var filtersPresented = false

  init(
    filters: Filters,
    libraryRepository: LibraryRepository
  ) {
    self.filters = filters
    self.libraryRepository = libraryRepository
  }

  var body: some View {
    contentView
      .navigationBarTitle(String.library, displayMode: .inline)
      .sheet(isPresented: $filtersPresented) {
        FiltersView(libraryRepository: libraryRepository, filters: filters)
          .background(Color.background.edgesIgnoringSafeArea(.all))
      }
  }
}

// MARK: - private
private extension LibraryView {
  var contentControlsSection: some View {
    VStack {
      searchAndFilterControls
        .padding(.top, 15)
      
      if !libraryRepository.currentAppliedFilters.isEmpty {
        filtersView
          .padding(.top, 10)
      }
      
      numberAndSortView
        .padding(.vertical, 10)
    }
    .padding(.horizontal, .sidePadding)
    .background(Color.background)
  }

  var searchField: some View {
    SearchFieldView(searchString: filters.searchStr) { searchString in
      filters.searchStr = searchString
      updateFilters()
    }
  }

  var searchAndFilterControls: some View {
    HStack {
      searchField
      
      Spacer()

      Button {
        filtersPresented = true
      } label: {
        Image("filter")
          .foregroundColor(.iconButton)
          .frame(width: .filterButtonSide, height: .filterButtonSide)
      }
      .accessibility(label: Text("Filter Library"))
      .padding([.horizontal], .searchFilterPadding)
    }
  }

  var numberAndSortView: some View {
    HStack {
      Text("\(libraryRepository.totalContentNum) \(String.tutorials.capitalized)")
        .font(.uiLabelBold)
        .foregroundColor(.contentText)

      Spacer()

      Button {
        changeSort()
      } label: {
        HStack {
          Image("sort")
            .foregroundColor(.textButtonText)
          if [.loading, .loadingAdditional].contains(libraryRepository.state) {
            Text(filters.sortFilter.name)
              .font(.uiLabel)
              .foregroundColor(.gray)
          } else {
            Text(filters.sortFilter.name)
              .font(.uiLabelBold)
              .foregroundColor(.textButtonText)
          }
        }
      }.disabled([.loading, .loadingAdditional].contains(libraryRepository.state))
    }
  }

  var filtersView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: .filterSpacing) {
        if filters.applied.count > 1 {
          AppliedFilterTagButton(name: String.resetFilters, type: .destructive) {
            filters.removeAll()
            libraryRepository.filters = filters
          }
        }
        
        ForEach(filters.applied, id: \.self) { filter in
          AppliedFilterTagButton(name: filter.filterName, type: .default) {
            if filter.isSearch {
              filters.searchQuery = nil
            } else {
              filter.isOn.toggle()
              filters.all.update(with: filter)
            }
            filters.commitUpdates()
            libraryRepository.filters = filters
          }
        }
      }
      .padding([.horizontal], .sidePadding)
    }
    .padding([.horizontal], -.sidePadding)
  }

  func updateFilters() {
    filters.searchQuery = filters.searchStr
    libraryRepository.filters = filters
  }

  func changeSort() {
    filters.changeSortFilter()
    libraryRepository.filters = filters
  }

  var contentView: some View {
    ContentListView(
      contentRepository: libraryRepository,
      downloadService: downloadService,
      contentScreen: .library,
      header: contentControlsSection
    )
  }
}

private extension CGFloat {
  static let filterButtonSide: CGFloat = 27
  static let searchFilterPadding: CGFloat = 15
  static let filterSpacing: CGFloat = 6
  static let filtersPaddingTop: CGFloat = 12
}
