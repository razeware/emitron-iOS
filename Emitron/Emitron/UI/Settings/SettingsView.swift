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

// These views could really do with a refactor. The data flow is a mess

enum SettingsLayout {
  static let rowSpacing: CGFloat = 11
}

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @EnvironmentObject var sessionController: SessionController
  @EnvironmentObject var tabViewModel: TabViewModel
  @ObservedObject private var settingsManager = SettingsManager.current
  @State private var licensesPresented: Bool = false
  var showLogoutButton: Bool
  
  var body: some View {
    NavigationView {
      VStack {
        
        SettingsList(settingsManager: _settingsManager)
          .navigationBarTitle(Constants.settings)
          .navigationBarItems(trailing: dismissButton)
          .padding([.horizontal], 20)
        
        Section(header:
          HStack {
            Text("App Icon")
              .font(.uiTitle4)
              .foregroundColor(.titleText)
            
            Spacer()
          }
            .padding([.top], 20)
        ) {
          IconChooserView()
        }
        .padding([.horizontal], 20)
        
        Spacer()
        
        Button(action: {
          self.licensesPresented.toggle()
        }) {
          Text("Software Licenses")
        }
          .sheet(isPresented: $licensesPresented) {
            LicenseListView(visible: self.$licensesPresented)
          }
          .padding([.bottom], 25)
        
        if showLogoutButton {
          VStack {
            if sessionController.user != nil {
              Text("Logged in as \(sessionController.user?.username ?? "")")
                .font(.uiCaption)
                .foregroundColor(.contentText)
            }
            MainButtonView(title: "Sign Out", type: .destructive(withArrow: true)) {
              self.presentationMode.wrappedValue.dismiss()
              // This is hacky. But without it, the sheet doesn't actually dismiss.
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sessionController.logout()
                self.tabViewModel.selectedTab = .library
              }
            }
          }
          .padding([.bottom, .horizontal], 18)
        }
      }
        .background(Color.backgroundColor)
    }
      .navigationViewStyle(StackNavigationViewStyle())
  }
  
  var dismissButton: some View {
    Button(action: {
      self.presentationMode.wrappedValue.dismiss()
    }) {
      Image.close
        .foregroundColor(.iconButton)
    }
  }
}

//#if DEBUG
//struct SettingsView_Previews: PreviewProvider {
//  static var previews: some View {
//    SwiftUI.Group {
//      settingsView.colorScheme(.dark)
//      settingsView.colorScheme(.light)
//    }
//  }
//
//  static var settingsView: some View {
//    SettingsView(showLogoutButton: true)
//      .background(Color.backgroundColor)
//  }
//}
//#endif
