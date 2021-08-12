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
  @EnvironmentObject var sessionController: SessionController
  @EnvironmentObject var tabViewModel: TabViewModel
  @ObservedObject private var settingsManager: SettingsManager
  @State private var licensesPresented = false

  init(settingsManager: SettingsManager) {
    self.settingsManager = settingsManager
  }
  
  var body: some View {
      VStack {
        SettingsList(
          settingsManager: _settingsManager,
          canDownload: sessionController.user?.canDownload ?? false
        ).padding([.horizontal], 20)
        
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

        Button {
          licensesPresented.toggle()
        } label: {
          Text("Software Licenses")
        }
        .sheet(isPresented: $licensesPresented) {
            LicenseListView(visible: $licensesPresented)
        }
        .padding([.bottom], 25)
        
          VStack {
            if sessionController.user != nil {
              Text("Logged in as \(sessionController.user?.username ?? "")")
                .font(.uiCaption)
                .foregroundColor(.contentText)
            }
            MainButtonView(title: "Sign Out", type: .destructive(withArrow: true)) {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sessionController.logout()
                tabViewModel.selectedTab = .library
              }
            }
          }
          .padding([.bottom, .horizontal], 18)
      }.navigationBarTitle(String.settings)
      .background(Color.backgroundColor.edgesIgnoringSafeArea(.all))
  }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {

  static var previews: some View {
    SwiftUI.Group {
      settingsView.preferredColorScheme(.dark)
      settingsView.preferredColorScheme(.light)
    }
  }

  static var settingsView: some View {
    SettingsView(settingsManager: EmitronApp.emitronObjects().settingsManager)
      .background(Color.backgroundColor)
      .environmentObject(EmitronApp.emitronObjects().sessionController)
  }
}
#endif
