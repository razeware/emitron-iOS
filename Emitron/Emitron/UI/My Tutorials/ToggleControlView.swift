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

struct ToggleControlView: View {
  @State var toggleState: MyTutorialsState
  var toggleUpdated: ((MyTutorialsState) -> Void)?
  
  var body: some View {
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: 1)
        .fill(Color.toggleLineDeselected)
        .frame(height: 2)
      
      HStack {
        toggleButton(for: .inProgress)
        toggleButton(for: .completed)
        toggleButton(for: .bookmarked)
      }
    }
  }
  
  private func toggleButton(for state: MyTutorialsState) -> some View {
    Button(action: {
      guard state != self.toggleState else { return }
      
      self.toggleState = state
      self.toggleUpdated?(state)
      MessageBus.current.dismiss()
    }) {
      toggleButtonContent(for: state)
    }
  }
  
  private func toggleButtonContent(for state: MyTutorialsState) -> some View {
    VStack {
      Text(state.displayString)
        .font(.uiButtonLabelSmall)
        .foregroundColor(toggleState == state ? Color.toggleTextSelected : .toggleTextDeselected)
      
      RoundedRectangle(cornerRadius: 1)
        .fill(toggleState == state ? Color.toggleLineSelected : .toggleLineDeselected)
        .frame(height: 2)
    }
  }
}

#if DEBUG
struct ToggleControlView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      tabs.colorScheme(.light)
      tabs.colorScheme(.dark)
    }
  }
  
  static var tabs: some View {
    VStack(spacing: 40) {
      ToggleControlView(toggleState: .inProgress)
      ToggleControlView(toggleState: .completed)
      ToggleControlView(toggleState: .bookmarked)
    }
      .padding([.vertical], 40)
      .padding([.horizontal], 10)
      .background(Color.backgroundColor)
  }
}
#endif
