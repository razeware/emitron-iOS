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

// These views could really do with a refactor. The data flow is a mess

struct SettingsView: View {
  @State private var settingsOptionsPresented: Bool = false
  @State private var licensesPresented: Bool = false
  @State var selectedOption: SettingsOption = .playbackSpeed
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @EnvironmentObject var sessionController: SessionController
  private var showLogoutButton: Bool
  
  init(showLogoutButton: Bool) {
    self.showLogoutButton = showLogoutButton
  }
  
  var body: some View {
    VStack {
      HStack {
        Rectangle()
          .frame(width: 27, height: 27, alignment: .center)
          .foregroundColor(.clear)
          .padding([.leading], 18)
        
        Spacer()
        
        Text(Constants.settings)
          .font(.uiTitle5)
          .foregroundColor(.titleText)
          .padding([.top], 20)
        
        Spacer()
        
        SwiftUI.Group {
          Button(action: {
            self.presentationMode.wrappedValue.dismiss()
          }) {
            Image.close
              .frame(width: 27, height: 27, alignment: .center)
              .padding(.trailing, 18)
              .padding([.top], 20)
              .foregroundColor(.iconButton)
          }
        }
      }
      VStack(spacing: 0) {
        ForEach(SettingsOption.allCases) { option in
          TitleDetailView(callback: {
            self.selectedOption = option
            
            // Only navigate to SettingsOptionsView if view isn't a toggle
            if !option.isToggle {
              self.settingsOptionsPresented.toggle()
            } else {
              switch option {
              case .closedCaptionOn:
                SettingsManager.current.closedCaptionOn.toggle()
              case .wifiOnlyDownloads:
                SettingsManager.current.wifiOnlyDownloads.toggle()
              case .downloadQuality, .playbackSpeed:
                // No-op
                return
              }
            }
          }, title: option.title,
             detail: self.populateDetail(for: option),
             isToggle: option.isToggle,
             isOn: self.isOn(for: option),
             rightImage: Image(systemName: "chevron.right"))
            .sheet(isPresented: self.$settingsOptionsPresented) {
              SettingsOptionsView(
                isPresented: self.$settingsOptionsPresented,
                isOn: false,
                selectedSettingsOption: self.$selectedOption
              )
            }
        }
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
            self.sessionController.logout()
            self.presentationMode.wrappedValue.dismiss()
          }
        }
        .padding([.bottom, .horizontal], 18)
      }
    }
    .background(Color.modalBackground)
  }
  
  private func populateDetail(for option: SettingsOption) -> String {
    switch option {
    case .closedCaptionOn, .wifiOnlyDownloads:
      return ""
    case .downloadQuality:
      return SettingsManager.current.downloadQuality.display
    case .playbackSpeed:
      return SettingsManager.current.playbackSpeed.display
    }
  }
  
  private func isOn(for option: SettingsOption) -> Bool {
    switch option {
    case .closedCaptionOn:
      return SettingsManager.current.closedCaptionOn
    case .wifiOnlyDownloads:
      return SettingsManager.current.wifiOnlyDownloads
    default:
      return false
    }
  }
}
