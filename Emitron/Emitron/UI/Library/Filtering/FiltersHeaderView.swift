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

private enum Layout {
  enum Padding {
    static let overall: CGFloat = 12
    static let textTrailing: CGFloat = 15
  }
  
  static let cornerRadius: CGFloat = 9
  static let imageSize: CGFloat = 15
}

struct FiltersHeaderView: View {
  var filterGroup: FilterGroup
  @ObservedObject var filters: Filters
  
  @State var isExpanded: Bool = false
  
  var body: some View {
    VStack {
      Button(action: {
        self.isExpanded.toggle()
      }) {
        HStack {
          Text(filterGroup.type.name)
            .foregroundColor(.titleText)
            .font(.uiLabelBold)
          
          Spacer()
          
          Text(isExpanded ? "Hide (\(numOfOnFilters))" : "Show (\(numOfOnFilters))")
            .foregroundColor(.contentText)
            .font(.uiLabelBold)
        }
        .padding([.top, .bottom], Layout.Padding.overall)
        .padding([.trailing, .leading], Layout.Padding.textTrailing)
        .background(Color.filterHeaderBackground)
        .cornerRadius(Layout.cornerRadius)
      }
        .accessibility(label: Text(filterGroup.type.name))
        
      if isExpanded {
        expandedView
      }
    }
  }
  
  private var numOfOnFilters: Int {
    filterGroup.filters.filter(\.isOn).count
  }
  
  private var expandedView: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(Array(filterGroup.filters), id: \.self) { filter in
        TitleCheckmarkView(name: filter.filterName, isOn: filter.isOn, onChange: { _ in
          filter.isOn.toggle()
          self.filters.update(with: filter)
        })
          .padding([.leading, .trailing], 14)
      }
    }
  }
}

#if DEBUG
struct FilterGroupView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      filters.colorScheme(.dark)
      filters.colorScheme(.light)
    }
  }
  
  static var filters: some View {
    let filters = Param
      .filters(for: [.difficulties(difficulties: [.beginner, .intermediate, .advanced])])
      .map { Filter(groupType: .difficulties, param: $0, isOn: false) }
    
    return VStack {
      FiltersHeaderView(
        filterGroup: FilterGroup(type: .difficulties, filters: filters),
        filters: Filters(),
        isExpanded: true
      )
      FiltersHeaderView(
        filterGroup: FilterGroup(type: .categories, filters: filters),
        filters: Filters()
      )
    }
      .padding()
      .background(Color.backgroundColor)
  }
}
#endif
