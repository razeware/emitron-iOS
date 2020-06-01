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

struct FiltersView: View {
  @ObservedObject var libraryRepository: LibraryRepository
  @ObservedObject var filters: Filters
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  var body: some View {
    VStack {
      
      HStack(alignment: .center) {
        
        Rectangle()
          .frame(width: 27, height: 27, alignment: .center)
          .foregroundColor(.clear)
          .padding([.leading], 18)
        
        Spacer()
        
        Text("Filters")
          .font(.uiTitle5)
          .foregroundColor(.titleText)
        
        Spacer()
        
        Button(action: {
          if Set(self.libraryRepository.nonPaginationParameters) != Set(self.filters.appliedParameters) {
            self.revertBackToPreviousFilters()
          }
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Image.close
            .frame(width: 27, height: 27, alignment: .center)
            .padding(.trailing, 18)
            .foregroundColor(.iconButton)
        }
      }
      .padding(.top, 20)
      
      constructScrollView()
        .padding([.leading, .trailing, .top], 20)
      
      HStack {
        
        MainButtonView(title: "Clear All", type: .secondary(withArrow: false)) {
          self.filters.removeAll()
          self.libraryRepository.filters = self.filters
          self.presentationMode.wrappedValue.dismiss()
        }
        .padding([.trailing], 10)
        
        // TODO: Figure out how best to handle NOT updating filters, but seeing which ones SHOULD get updated to compare to
        // Which ones are currently being applied to the content listing
        applyOrCloseButton()
      }
      .padding([.leading, .trailing, .bottom], 18)
    }
    .background(Color.backgroundColor)
  }
  
  private func constructScrollView() -> some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(filters.filterGroups, id: \.self) { filterGroup in
          self.constructFilterView(filterGroup: filterGroup)
        }
      }
        .padding([.bottom], 30)
    }
  }
  
  private func constructFilterView(filterGroup: FilterGroup) -> FiltersHeaderView {
    FiltersHeaderView(
      filterGroup: filterGroup,
      filters: self.filters,
      isExpanded: filterGroup.numApplied > 0
    )
  }
  
  private func applyOrCloseButton() -> MainButtonView {
    let equalSets = Set(libraryRepository.nonPaginationParameters) == Set(filters.appliedParameters)
    let title = equalSets ? "Close" : "Apply"
    
    let buttonView = MainButtonView(title: title, type: .primary(withArrow: false)) {
      self.libraryRepository.filters = self.filters
      self.presentationMode.wrappedValue.dismiss()
    }
    
    return buttonView
  }
  
  private func revertBackToPreviousFilters() {
    // Update filters with the currentFilters on contentsMC, to keep them in sync (aka, remove them)
    
    // First, turn all applied off
    self.filters.applied.forEach { filter in
      filter.isOn = false
      self.filters.all.update(with: filter)
    }
    
    // Then, turn all the currentAppliedFilters things on
    self.libraryRepository.currentAppliedFilters.forEach { filter in
      filter.isOn = true
      self.filters.all.update(with: filter)
    }
  }
}
