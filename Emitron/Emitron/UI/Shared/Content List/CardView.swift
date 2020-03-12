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
import KingfisherSwiftUI
import Combine

struct CardView: View {
  let model: ContentListDisplayable
  @ObservedObject var dynamicContentViewModel: DynamicContentViewModel

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          
          VStack(alignment: .leading, spacing: 5) {
            Text(name)
              .font(.uiTitle4)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .padding([.trailing], 15)
              .foregroundColor(.titleText)
            
            Text(model.cardViewSubtitle)
              .font(.uiCaption)
              .lineLimit(nil)
              .foregroundColor(.contentText)
            
            Spacer()
          }

          Spacer()

          KFImage(model.cardArtworkUrl)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .transition(.opacity)
            .cornerRadius(6)
            .padding([.bottom], 12)
        }

        Text(model.descriptionPlainText)
          .font(.uiCaption)
          .fixedSize(horizontal: false, vertical: true)
          .lineLimit(2)
          .lineSpacing(3)
          .foregroundColor(.contentText)
        
        HStack(spacing: 8) {
          if model.professional {
            ProTag()
          }
          
          completedTagOrReleasedAt
          
          Spacer()
          
          bookmarkButton
        }
        .padding([.top], 24)
      }
      .padding([.top, .horizontal], 15)
      .padding([.bottom], 20)
      
      progressBar
    }
    .background(Color.cardBackground)
    .cornerRadius(6)
    .onAppear {
      self.dynamicContentViewModel.initialiseIfRequired()
    }
  }
  
  private var name: String {
    guard let parentName = model.parentName, model.contentType == .episode else {
      return model.name
    }
    
    return "\(parentName): \(model.name)"
  }
  
  private var progressBar: AnyView? {
    if case .inProgress(let progress) = dynamicContentViewModel.viewProgress {
      return AnyView(ProgressBarView(progress: progress, isRounded: true, backgroundColor: .clear))
    } else {
      return nil
    }
  }
  
  private var completedTagOrReleasedAt: AnyView {
    if case .completed = dynamicContentViewModel.viewProgress {
      return AnyView(CompletedTag())
    } else {
      return AnyView(Text(model.releasedAtDateTimeString)
        .font(.uiCaption)
        .lineLimit(1)
        .foregroundColor(.contentText))
    }
  }
  
  private var bookmarkButton: AnyView? {
    guard dynamicContentViewModel.bookmarked else { return nil }
    
    return AnyView(
      Image.bookmark
        .resizable()
        .frame(width: 21, height: 21)
        .foregroundColor(Color.inactiveIcon)
    )
  }
}

/*
 // Commenting this out for now. It's really helpful for building the UI. But
 // it relies on the CardView not needing an observable object. However, without
 // that, it's really hard to get the dynamic updates happening as expected. I've
 // left it here cos it's quite useful. Switch the type, and you can get it running.
 
#if DEBUG
struct MockContentListDisplayable: ContentListDisplayable {
  var id: Int = 1
  var name: String = "Drawing in iOS with SwiftUI"
  var cardViewSubtitle: String = "iOS & Swift"
  var descriptionPlainText: String = "Learn about drawing using SwiftUI by creating custom controls using a combination of SwiftUI and something else that will be cut off"
  var professional: Bool = true
  var releasedAt = Date()
  var duration: Int = 10080
  var parentName: String?
  var contentType: ContentType = .collection
  var cardArtworkUrl: URL? = URL(string: "https://files.betamax.raywenderlich.com/attachments/collections/216/9eb9899d-47d0-429d-96f0-e15ac9542ecc.png")
  var ordinal: Int?
  var technologyTripleString: String = "Doesn't matter"
  var contentSummaryMetadataString: String = "Doesn't matter"
  var contributorString: String = "Deosn't matter"
  var videoIdentifier: Int?
}

struct MockDynamicContentDisplayable: DynamicContentDisplayable {
  var viewProgress: ContentViewProgressDisplayable = .notStarted
  var downloadProgress: DownloadProgressDisplayable = .downloadable
  var bookmarked: Bool = false
}

struct CardView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      list.colorScheme(.dark)
      
      list.colorScheme(.light)
    }
  }
  
  static var list: some View {
    List {
      CardView(
        model: MockContentListDisplayable(name: "Short Title", professional: false),
        dynamicContent: MockDynamicContentDisplayable()
      )
      CardView(
        model: MockContentListDisplayable(),
        dynamicContent: MockDynamicContentDisplayable(
          viewProgress: .inProgress(progress: 0.4),
          bookmarked: true
        )
      )
      CardView(
        model: MockContentListDisplayable(),
        dynamicContent: MockDynamicContentDisplayable(
          viewProgress: .completed
        )
      )
      CardView(
        model: MockContentListDisplayable(),
        dynamicContent: MockDynamicContentDisplayable(
          viewProgress: .inProgress(progress: 0.8)
        )
      )
      CardView(
        model: MockContentListDisplayable(),
        dynamicContent: MockDynamicContentDisplayable()
      )
      CardView(
        model: MockContentListDisplayable(),
        dynamicContent: MockDynamicContentDisplayable()
      )
    }
  }
}
#endif
*/
