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

struct SettingsList: View {
  @ObservedObject private var settingsManager: SettingsManager

  init(settingsManager: ObservedObject<SettingsManager>) {
    _settingsManager = settingsManager
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(SettingsOption.allCases, content: row)
    }
  }
  
  private func row(for option: SettingsOption) -> AnyView {
    switch option {
    case .closedCaptionOn:
      return AnyView(SettingsToggleRow(
        title: option.title,
        isOn: $settingsManager.closedCaptionOn
      ))
    case .wifiOnlyDownloads:
      return AnyView(SettingsToggleRow(
        title: option.title,
        isOn: $settingsManager.wifiOnlyDownloads
      ))
    case .downloadQuality:
      return AnyView(
        NavigationLink(
          destination: SettingsSelectionView(
            title: option.title,
            settingsOption: $settingsManager.downloadQuality
          )
        ) {
          SettingsDisclosureRow(title: option.title, value: settingsManager.downloadQuality.display)
        })
    case .playbackSpeed:
      return AnyView(
        NavigationLink(
          destination: SettingsSelectionView(
            title: option.title,
            settingsOption: $settingsManager.playbackSpeed
          )
        ) {
          SettingsDisclosureRow(title: option.title, value: settingsManager.playbackSpeed.display)
        })
    }
  }
}

struct SettingsList_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUI.Group {
      list.colorScheme(.dark)
      list.colorScheme(.light)
    }
  }
  
  static var list: some View {
    SettingsList( settingsManager: .init(initialValue: .current) )
      .background(Color.backgroundColor)
  }
}
