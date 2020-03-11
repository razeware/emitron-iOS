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

struct LicenseListView: View {
  var licenses: [FossLicense] = FossLicense.load()
  @Binding var visible: Bool
  
  var body: some View {
    NavigationView {
      VStack {
        Text("This app uses a selection of fantastic 3rd-party libraries. You can see details and their licenses below.")
          .font(.uiLabel)
          .foregroundColor(.contentText)
          
        List(licenses) { license in
          NavigationLink(destination: LicenseDetailView(license: license)) {
            Text(license.name)
              .font(.uiLabel)
              .foregroundColor(.contentText)
          }
            .navigationBarTitle("Software Licenses")
            .navigationBarItems(trailing: self.dismissButton)
        }
      }
        .padding(10)
        .background(Color.backgroundColor)
    }
      .navigationViewStyle(StackNavigationViewStyle())
  }
  
  var dismissButton: some View {
    Button(action: {
      self.visible.toggle()
    }) {
      Image.close
        .foregroundColor(.iconButton)
    }
  }
}

struct LicenseListView_Previews: PreviewProvider {
  @State static var visible: Bool = true
  
  static var previews: some View {
    SwiftUI.Group {
      LicenseListView(licenses: FossLicense.load(), visible: $visible).colorScheme(.light)
      LicenseListView(licenses: FossLicense.load(), visible: $visible).colorScheme(.dark)
    }
  }
}
