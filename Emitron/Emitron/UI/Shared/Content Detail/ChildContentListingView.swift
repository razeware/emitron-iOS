// Copyright (c) 2020 Razeware LLC
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

struct ChildContentListingView: View {
  @ObservedObject var childContentsViewModel: ChildContentsViewModel
  @Binding var currentlyDisplayedVideoPlaybackViewModel: VideoPlaybackViewModel?
  @EnvironmentObject var sessionController: SessionController
  
  var body: some View {
    childContentsViewModel.initialiseIfRequired()
    return courseDetailsSection
  }
}

// MARK: - private
private extension ChildContentListingView {
  @ViewBuilder private var courseDetailsSection: some View {
    switch childContentsViewModel.state {
    case .failed:
      reloadView
    case .hasData:
      coursesSection
    case .loading, .loadingAdditional, .initial:
      loadingView
    }
  }
  
  var coursesSection: some View {
    SwiftUI.Group {
      Section {
        if childContentsViewModel.contents.count > 1 {
          Text("Course Episodes")
            .font(.uiTitle2)
            .foregroundColor(.titleText)
            .padding([.top, .bottom])
        }
      }
        .listRowBackground(Color.backgroundColor)
        .accessibility(identifier: "childContentList")
        
      if childContentsViewModel.groups.count > 1 {
        ForEach(childContentsViewModel.groups, id: \.id) { group in
          // By default, iOS 14 shows headers in upper case. Text casing is changed by the textCase modifier which is not available on previous versions.
          if #available(iOS 14, *) {
            Section(header: CourseHeaderView(name: group.name)) {
              episodeListing(data: childContentsViewModel.contents(for: group.id))
            }
            .background(Color.backgroundColor)
            .textCase(nil)
          } else {
            // Default behavior for iOS 13 and lower.
            Section(header: CourseHeaderView(name: group.name)) {
              episodeListing(data: childContentsViewModel.contents(for: group.id))
            }
            .background(Color.backgroundColor)
          }
        }
      } else if !childContentsViewModel.groups.isEmpty {
        episodeListing(data: childContentsViewModel.contents)
      }
    }
    .padding(0)
  }

  var loadingView: some View {
    HStack {
      Spacer()
      LoadingView()
      Spacer()
    }
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.backgroundColor)
      .background(Color.backgroundColor)
  }

  var reloadView: MainButtonView {
    .init(
      title: "Reload",
      type: .primary(withArrow: false),
      callback: childContentsViewModel.reload
    )
  }
  
  func episodeListing(data: [ChildContentListDisplayable]) -> some View {
    let onlyContentWithVideoID = data
      .filter { $0.videoIdentifier != nil }
      .sorted {
        guard let lhs = $0.ordinal, let rhs = $1.ordinal else { return true }
        return lhs < rhs
      }
    
    return ForEach(onlyContentWithVideoID, id: \.id) { model in
      episodeRow(model: model)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
    }
  }
  
  @ViewBuilder func episodeRow(model: ChildContentListDisplayable) -> some View {
    let childDynamicContentViewModel = childContentsViewModel.dynamicContentViewModel(for: model.id)
    
    if !sessionController.canPlay(content: model) {
      TextListItemView(
        dynamicContentViewModel: childDynamicContentViewModel,
        content: model
      )
      .padding([.horizontal, .bottom], 20)
    } else if sessionController.sessionState == .offline && !sessionController.hasCurrentDownloadPermissions {
      Button(action: {
        MessageBus.current
          .post(message: Message(level: .warning, message: .videoPlaybackExpiredPermissions))
      }) {
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
        .padding([.horizontal, .bottom], 20)
      }
    } else {
      Button(action: {
        currentlyDisplayedVideoPlaybackViewModel = childDynamicContentViewModel.videoPlaybackViewModel(
          apiClient: sessionController.client,
          dismissClosure: {
            currentlyDisplayedVideoPlaybackViewModel = nil
          }
        )
      }) {
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
        .padding([.horizontal, .bottom], 20)
      }
    }
  }
}

//struct ChildContentListingView_Previews: PreviewProvider {
//  static var previews: some View {
//    ChildContentListingView()
//  }
//}
