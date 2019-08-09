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

struct ToggleControlView: View {
  
  @State var inProgressSelected: Bool = true
  @State var completedSelected: Bool = false
  @State var bookmarkedSelected: Bool = false
  
  var inProgressClosure: (()->())?
  var completedClosure: (()->())?
  var bookmarkedClosure: (()->())?
  
  var body: some View {
    HStack {
      
      Button(action: {
        self.inProgressSelected = true
        self.completedSelected = false
        self.bookmarkedSelected = false
        self.inProgress()
      }) {
        
        VStack {
          
          if self.inProgressSelected {
            self.updateToggleToOn(with: "In Progress")
          } else {
            self.updateToggleToOff(with: "In Progress")
          }
        }
      }
      
      Button(action: {
        self.inProgressSelected = false
        self.completedSelected = true
        self.bookmarkedSelected = false
        self.completed()
      }, label: {
        VStack {
          
          if self.completedSelected {
            self.updateToggleToOn(with: "Completed")
            } else {
              self.updateToggleToOff(with: "Completed")
          }
        }
      })
      
      Button(action: {
        self.inProgressSelected = false
        self.completedSelected = false
        self.bookmarkedSelected = true
        self.bookmarked()
      }, label: {
        
        VStack {
          
          if self.bookmarkedSelected {
            self.updateToggleToOn(with: "Bookmarks")
            } else {
              self.updateToggleToOff(with: "Bookmarks")
          }
        }
      })
    }
  }
  
  private func updateToggleToOn(with text: String) -> AnyView {
    
    let stackView = VStack {
      Text(text)
      .lineLimit(1)
      .font(.uiButtonLabelSmall)
      .foregroundColor(Color.appGreen)
      .frame(width: 80, height: nil, alignment: .center)
      
      Rectangle()
      .frame(maxWidth: 120, maxHeight: 2)
      .foregroundColor(Color.appGreen)
    }
    
    return AnyView(stackView)
  }
  
  private func updateToggleToOff(with text: String) -> AnyView {
    
    let stackView = VStack {
      Text(text)
      .lineLimit(1)
      .font(.uiButtonLabelSmall)
      .foregroundColor(Color.coolGrey)
      .frame(width: 80, height: nil, alignment: .center)
      
      Rectangle()
      .frame(maxWidth: 120, maxHeight: 2)
      .foregroundColor(Color.coolGrey)
    }
    
    return AnyView(stackView)
  }
  
  private func inProgress() {
    print("In progress tapped!")
    inProgressClosure?()
  }
  
  private func completed() {
    print("Completed tapped!")
    completedClosure?()
  }
  
  private func bookmarked() {
    print("Bookmarked tapped!")
    bookmarkedClosure?()
  }
}

#if DEBUG
struct ToggleControlView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleControlView()
    }
}
#endif
