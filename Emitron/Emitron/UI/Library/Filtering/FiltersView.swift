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

struct FiltersView: View {
  
  @EnvironmentObject var contentsMC: ContentsMC
  @EnvironmentObject var filters: Filters
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
          .font(.uiHeadline)
          .foregroundColor(.appBlack)
        
        Spacer()
        
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Image("close")
            .frame(width: 27, height: 27, alignment: .center)
            .padding(.trailing, 18)
            .foregroundColor(.battleshipGrey)
        }
      }
      .padding(.top, 20)
      
      constructScrollView()
        .padding([.leading, .trailing, .top], 20)
      
      HStack {
        
        MainButtonView(title: "Clear all", type: .secondary(withArrow: false)) {
          self.presentationMode.wrappedValue.dismiss()
          self.filters.removeAll()
          self.contentsMC.updateFilters(newFilters: self.filters)
        }
        .padding([.trailing], 10)
        
        // TODO: Figure out how best to handle NOT updating filters, but seeing which ones SHOULD get updated to compare to
        // Which ones are currently being applied to the content listing
        applyOrCloseButton()
      }
      .padding([.leading, .trailing], 18)
    }
    .background(Color.paleGrey)
  }
  
  // Is ScrollView<VStack<ForEach<[FilterGroup], FilterGroup, FiltersHeaderView>>> actually more performance than AnyView?
  private func constructScrollView() -> ScrollView<VStack<ForEach<[FilterGroup], FilterGroup, FiltersHeaderView>>> {

    let scrollView = ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        
        ForEach(filters.filterGroups, id: \.self) { filterGroup in
          self.constructFilterView(filterGroup: filterGroup)
        }
      }
    }
    return scrollView
  }
  
  private func constructFilterView(filterGroup: FilterGroup) -> FiltersHeaderView {
    let filtersView = FiltersHeaderView(filterGroup: filterGroup)
    return filtersView
  }
  
  private func applyOrCloseButton() -> MainButtonView {
    
    let equalSets = Set(contentsMC.currentParameters) == Set(filters.appliedParameters)
    let title = equalSets ? "Close" : "Apply"
    
    let buttonView = MainButtonView(title: title, type: .primary(withArrow: false)) {
      self.presentationMode.wrappedValue.dismiss()
      self.contentsMC.updateFilters(newFilters: self.filters)
    }
    
    return buttonView
  }
}
