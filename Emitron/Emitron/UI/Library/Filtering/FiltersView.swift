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
  
//  @EnvironmentObject var contentsMC: ContentsMC
  @Binding var isPresented: Bool
  
  //TODO: How do you initialize AND pass binding things through?
  //  private var filters: Filters
  //
  //  init(with filters: Filters) {
  //    self.filters = filters
  //  }
  
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
          self.isPresented = false
          //TODO: This should probably definitely not be here in the end
          //TODO: Put this back
          // self.contentsMC.filters = self.filters
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
    }
    .background(Color.paleGrey)
      //TODO: In the current beta onDisappear() doesn’t seem to get called.
      .onDisappear {
        //TODO: Put this back
        // self.contentsMC.filters = self.filters
      }
  }
  
  func constructScrollView() -> AnyView {
    let filters = DataManager.current.filters!
    
    let scrollView = ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        
        ForEach(filters.filterGroups, id: \.self) { filterGroup in
          self.constructFilterView(filterGroup: filterGroup)
        }
      }
    }
    return AnyView(scrollView)
  }
  
  func constructFilterView(filterGroup: FilterGroup) -> AnyView {
    let filtersView = FiltersHeaderView(filterGroup: filterGroup)
    return AnyView(filtersView)
  }
}
