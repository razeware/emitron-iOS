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

struct SnackbarState {
  enum Status: String {
    case success, warning, error
    
    var color: Color {
      switch self {
      case .success:
        return .snackSuccess
      case .warning:
        return .snackWarning
      case .error:
        return .snackError
      }
    }
    
    var tagText: String {
      rawValue.uppercased()
    }
  }
  
  let status: Status
  let message: String
}

struct SnackbarView: View {
  var state: SnackbarState
  @Binding var visible: Bool
  
  var body: some View {
    HStack {
      Text(state.message)
        .font(.uiBodyCustom)
        .foregroundColor(.snackText)
        .animation(.none)
      
      Spacer()
      
      Button(action: {
        withAnimation {
          self.visible.toggle()
        }
      }) {
        Image.closeWhite
          .resizable()
          .frame(width: 18, height: 18)
      }.foregroundColor(.snackText)
    }
    .padding()
    .background(state.status.color)
  }
}

struct SnackbarView_Previews: PreviewProvider {
  @State static var visible = true
  static var previews: some View {
    VStack {
      SnackbarView(state: SnackbarState(status: .error, message: "There was a problem."), visible: $visible)
      SnackbarView(state: SnackbarState(status: .warning, message: "We're going orange."), visible: $visible)
      SnackbarView(state: SnackbarState(status: .success, message: "Everything looks peachy."), visible: $visible)
    }
  }
}
