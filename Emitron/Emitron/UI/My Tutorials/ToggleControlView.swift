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
  
  var body: some View {
    HStack {
      
      Button(action: {
        if self.inProgressSelected == false {
          self.inProgressSelected.toggle()
        }
        
        if self.completedSelected == true {
          self.completedSelected.toggle()
        }
        
        if self.bookmarkedSelected == true {
          self.bookmarkedSelected.toggle()
        }
        
        self.inProgress()
      }) {
        
        VStack {
          
          if self.inProgressSelected {
            
            Text("In Progress")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
            .foregroundColor(Color.appGreen)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.appGreen)
          } else {
            
            Text("In Progress")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
              .foregroundColor(Color.coolGrey)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.coolGrey)
          }
        }
      }
      
      Spacer()
      
      Button(action: {
        if self.inProgressSelected == true {
          self.inProgressSelected.toggle()
        }
        
        if self.completedSelected == false {
          self.completedSelected.toggle()
        }
        
        if self.bookmarkedSelected == true {
          self.bookmarkedSelected.toggle()
        }
        
        self.completed()
      }, label: {
        VStack {
          
          if self.completedSelected {
            
            Text("Completed")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
            .foregroundColor(Color.appGreen)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.appGreen)
          } else {
            
            Text("Completed")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
            .foregroundColor(Color.coolGrey)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.coolGrey)
          }
        }
      })
      
      Spacer()
      
      Button(action: {
        if self.inProgressSelected == true {
          self.inProgressSelected.toggle()
        }
        
        if self.completedSelected == true {
          self.completedSelected.toggle()
        }
        
        if self.bookmarkedSelected == false {
          self.bookmarkedSelected.toggle()
        }
        
        self.bookmarked()
      }, label: {
        
        VStack {
          
          if self.bookmarkedSelected {
            
            Text("Bookmarks")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
            .foregroundColor(Color.appGreen)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.appGreen)
          } else {
            
            Text("Bookmarks")
            .lineLimit(1)
            .font(.uiButtonLabelSmall)
            .foregroundColor(Color.coolGrey)
            
            Rectangle()
            .frame(maxWidth: 113, maxHeight: 2)
            .foregroundColor(Color.coolGrey)
          }
        }
      })
      
    }
  }
  
  private func inProgress() {
    print("In progress tapped!")
  }
  
  private func completed() {
    print("Completed tapped!")
  }
  
  private func bookmarked() {
    print("Bookmarked tapped!")
  }
}

#if DEBUG
struct ToggleControlView_Previews: PreviewProvider {
    static var previews: some View {
        ToggleControlView()
    }
}
#endif
