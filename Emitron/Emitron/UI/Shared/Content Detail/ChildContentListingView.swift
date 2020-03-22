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
  
  private var courseDetailsSection: AnyView {
    switch childContentsViewModel.state {
    case .failed:
      return AnyView(reloadView)
    case .hasData:
      return AnyView(coursesSection)
    case .loading, .loadingAdditional:
      return AnyView(loadingView)
    case .initial:
      return AnyView(loadingView)
    }
  }
  
  var coursesSection: some View {
    Section {
      if self.childContentsViewModel.contents.count > 1 {
        Text("Course Episodes")
          .font(.uiTitle2)
          .foregroundColor(.titleText)
          .padding([.top], -5)
        
        if childContentsViewModel.groups.count > 1 {
          ForEach(childContentsViewModel.groups, id: \.id) { group in
            
            Section(header: CourseHeaderView(name: group.name)) {
              self.episodeListing(data: self.childContentsViewModel.contents(for: group.id))
            }
          }
        } else {
          if !childContentsViewModel.groups.isEmpty {
            self.episodeListing(data: childContentsViewModel.contents)
          }
        }
      }
    }
    .listRowBackground(Color.backgroundColor)
    .accessibility(identifier: "childContentList")
  }
  
  private func episodeListing(data: [ChildContentListDisplayable]) -> some View {
    let onlyContentWithVideoID = data
      .filter { $0.videoIdentifier != nil }
      .sorted(by: {
        guard let lhs = $0.ordinal, let rhs = $1.ordinal else { return true }
        return lhs < rhs
      })
    
    return ForEach(onlyContentWithVideoID, id: \.id) { model in
      self.episodeRow(model: model)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.backgroundColor)
    }
  }
  
  private func episodeRow(model: ChildContentListDisplayable) -> some View {
    
    let childDynamicContentViewModel = childContentsViewModel.dynamicContentViewModel(for: model.id)
    
    if !sessionController.canPlay(content: model) {
      return AnyView(
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
          .padding([.horizontal, .bottom], 20)
      )
    } else if sessionController.sessionState == .offline && !sessionController.hasCurrentDownloadPermissions {
      return AnyView(
        Button(action: {
          MessageBus.current
            .post(message: Message(level: .warning, message: Constants.videoPlaybackExpiredPermissions))
        }) {
          TextListItemView(
            dynamicContentViewModel: childDynamicContentViewModel,
            content: model
          )
            .padding([.horizontal, .bottom], 20)
        }
      )
    } else {
      return AnyView(Button(action: {
        self.currentlyDisplayedVideoPlaybackViewModel = childDynamicContentViewModel.videoPlaybackViewModel(
          apiClient: self.sessionController.client,
          dismissClosure: {
            self.currentlyDisplayedVideoPlaybackViewModel = nil
          }
        )
      }) {
        TextListItemView(
          dynamicContentViewModel: childDynamicContentViewModel,
          content: model
        )
          .padding([.horizontal, .bottom], 20)
      })
    }
  }
  
  private var loadingView: some View {
    HStack {
      Spacer()
      LoadingView()
      Spacer()
    }
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.backgroundColor)
      .background(Color.backgroundColor)
  }
  
  private var reloadView: AnyView? {
    AnyView(MainButtonView(title: "Reload", type: .primary(withArrow: false)) {
      self.childContentsViewModel.reload()
    })
  }
}

//struct ChildContentListingView_Previews: PreviewProvider {
//  static var previews: some View {
//    ChildContentListingView()
//  }
//}
