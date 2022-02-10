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

import SwiftUI

struct FiltersView: View {
  @ObservedObject private var libraryRepository: LibraryRepository
  @ObservedObject private var filters: Filters
  @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

  init(
    libraryRepository: LibraryRepository,
    filters: Filters
  ) {
    self.libraryRepository = libraryRepository
    self.filters = filters
  }
  
  var body: some View {
    VStack {
      HStack(alignment: .center) {
        Rectangle()
          .frame(width: 27, height: 27, alignment: .center)
          .foregroundColor(.clear)
          .padding([.leading], 18)
        
        Spacer()
        
        Text(String.filters)
          .font(.uiTitle5)
          .foregroundColor(.titleText)
        
        Spacer()

        Button {
          if Set(libraryRepository.nonPaginationParameters) != Set(filters.appliedParameters) {
            revertBackToPreviousFilters()
          }
          presentationMode.wrappedValue.dismiss()
        } label: {
          Image.close
            .frame(width: 27, height: 27, alignment: .center)
            .padding(.trailing, 18)
            .foregroundColor(.iconButton)
        }
      }
      .padding(.top, 20)
      
      constructScrollView()
        .padding([.horizontal, .top], 20)
      
      HStack {
        
        MainButtonView(title: "Reset Filters", type: .secondary(withArrow: false)) {
          filters.removeAll()
          libraryRepository.filters = filters
          presentationMode.wrappedValue.dismiss()
        }
        .padding([.trailing], 10)
        
        // TODO: Figure out how best to handle NOT updating filters, but seeing which ones SHOULD get updated to compare to
        // Which ones are currently being applied to the content listing
        applyFiltersButton()
      }
      .padding([.horizontal, .bottom], 18)
    }
    .background(Color.background)
  }
}

// MARK: - private
private extension FiltersView {
  func constructScrollView() -> some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(filters.filterGroups, id: \.self) { filterGroup in
          constructFilterView(filterGroup: filterGroup)
        }
      }
        .padding([.bottom], 30)
    }
  }
  
  func constructFilterView(filterGroup: FilterGroup) -> FiltersHeaderView {
    .init(
      filterGroup: filterGroup,
      filters: filters,
      isExpanded: filterGroup.numApplied > 0
    )
  }
  
  func applyFiltersButton() -> MainButtonView {
    let title = "Apply Filters"
    
    let buttonView = MainButtonView(title: title, type: .primary(withArrow: false)) {
      libraryRepository.filters = filters
      presentationMode.wrappedValue.dismiss()
    }
    
    return buttonView
  }
  
  func revertBackToPreviousFilters() {
    // Update filters with the currentFilters on contentsMC, to keep them in sync (aka, remove them)
    
    // First, turn all applied off
    filters.applied.forEach { filter in
      filter.isOn = false
      filters.all.update(with: filter)
    }
    
    // Then, turn all the currentAppliedFilters things on
    libraryRepository.currentAppliedFilters.forEach { filter in
      filter.isOn = true
      filters.all.update(with: filter)
    }
  }
}
