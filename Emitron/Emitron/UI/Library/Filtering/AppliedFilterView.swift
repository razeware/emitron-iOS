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

enum AppliedFilterType {
  case `default`
  case destructive
  
  var color: Color {
    switch self {
    case .default:
      return .secondaryButtonBackground
    case .destructive:
      return .destructiveButtonBackground
    }
  }
}

private enum Layout {
  struct Padding {
    let overall: CGFloat = 12
    let textTrailing: CGFloat = 2
  }
  
  static let padding = Padding()
  static let cornerRadius: CGFloat = 9
  static let imageSize: CGFloat = 15
}

struct AppliedFilterView: View {
  
  @EnvironmentObject var filters: Filters
  private var filter: Filter?
  private var type: AppliedFilterType
  private var name: String?
  private var filtersUpdateCallback: () -> Void
  
  init(filter: Filter? = nil, type: AppliedFilterType, name: String? = nil, filtersDidUpdate: @escaping () -> Void) {
    self.filter = filter
    self.type = type
    self.name = name
    self.filtersUpdateCallback = filtersDidUpdate
  }
  
  var body: some View {
    Button(action: {
      // If there's no filter passed through, it's a destructive one that should clear all, so we init a new Filters object
      if let filter = self.filter {
        if filter == self.filters.searchFilter {
          self.filters.searchQuery = nil
        } else {
          filter.isOn.toggle()
          self.filters.all.update(with: filter)
        }
        self.filters.commitUpdates()
      } else {
        self.filters.removeAll()
      }
      self.filtersUpdateCallback()
    }) {
      HStack {
        Text(filter?.filterName ?? name ?? "None")
          .foregroundColor(.buttonText)
          .font(.uiButtonLabelSmall)
          .padding([.trailing], Layout.padding.textTrailing)
        Image("closeWhite")
          .resizable()
          .frame(width: Layout.imageSize, height: Layout.imageSize)
          .foregroundColor(.buttonText)
      }
      .padding(.all, Layout.padding.overall)
        .background(type.color)
        .cornerRadius(Layout.cornerRadius)
    }
  }
}

#if DEBUG
struct AppliedFilterView_Previews: PreviewProvider {
  static var previews: some View {
    AppliedFilterView(filter: Filter.testFilter, type: .default) {
      print("This is just a test.")
    }
  }
}
#endif
