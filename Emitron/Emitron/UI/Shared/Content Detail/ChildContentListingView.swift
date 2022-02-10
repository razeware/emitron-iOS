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

struct ChildContentListingView: View {
  @ObservedObject private var childContentsViewModel: ChildContentsViewModel
  @Binding private var currentlyDisplayedVideoPlaybackViewModel: VideoPlaybackViewModel?
  @EnvironmentObject private var sessionController: SessionController
  @EnvironmentObject private var messageBus: MessageBus
  
  init(
    childContentsViewModel: ChildContentsViewModel,
    currentlyDisplayedVideoPlaybackViewModel: Binding<VideoPlaybackViewModel?>
  ) {
    self.childContentsViewModel = childContentsViewModel
    _currentlyDisplayedVideoPlaybackViewModel = currentlyDisplayedVideoPlaybackViewModel
  }

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
          HStack {
            Text("Course Episodes")
              .font(.uiTitle2)
              .kerning(-0.5)
              .foregroundColor(.titleText)
              .padding([.top, .bottom])
            Spacer()
          }.padding(.horizontal, 20)
        }
      }
      .listRowBackground(Color.background)
      .accessibility(identifier: "childContentList")
        
      if childContentsViewModel.groups.count > 1 {
        ForEach(childContentsViewModel.groups, id: \.id) { group in
          // By default, iOS 14 shows headers in upper case. Text casing is changed by the textCase modifier which is not available on previous versions.
          Section(header: CourseHeaderView(name: group.name)) {
            episodeListing(data: childContentsViewModel.contents(for: group.id))
          }
          .background(Color.background)
          .textCase(nil)
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
    .listRowInsets(.init())
    .listRowBackground(Color.background)
    .background(Color.background)
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
        .listRowInsets(.init())
        .listRowBackground(Color.background)
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
      Button {
        messageBus.post(message: Message(level: .warning, message: .videoPlaybackExpiredPermissions))
      } label: {
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
        .padding([.horizontal, .bottom], 20)
      }
    } else {
      Button {
        currentlyDisplayedVideoPlaybackViewModel = childDynamicContentViewModel.videoPlaybackViewModel(
          apiClient: sessionController.client,
          dismissClosure: {
            currentlyDisplayedVideoPlaybackViewModel = nil
          }
        )
      } label: {
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
        .padding([.horizontal, .bottom], 20)
      }
    }
  }
}

// struct ChildContentListingView_Previews: PreviewProvider {
//  static var previews: some View {
//    ChildContentListingView()
//  }
// }
