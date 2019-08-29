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

enum SettingsOption: Int, Identifiable {
  case videoPlaybackSpeed, downloads, downloadsQuality, subtitles
  
  var id: Int {
    return self.rawValue
  }
  
  var title: String {
    switch self {
      case .videoPlaybackSpeed: return "Video Playback Speed"
      case .downloads: return "Downloads (Wifi only)"
      case .downloadsQuality: return "Downloads Quality"
      case .subtitles: return "Subtitles"
    }
  }
  
  var detail: Detail {
    return Detail(option: self)
  }
  
  var isToggle: Bool {
    switch self {
      case .downloads, .subtitles: return true
      default: return false
    }
  }
  
  // In order to iterate through detailOptions, this needs to be a class that conforms to identifiable
  struct Detail: Identifiable {
    let option: SettingsOption
    
    var detailOptions: [String] {
      switch option {
        case .videoPlaybackSpeed: return ["1.0", "1.5", "2.0"]
        case .downloads: return ["Yes", "No"]
        case .downloadsQuality: return ["HD", "SD"]
        case .subtitles: return ["Yes", "No"]
      }
    }
    
    var id: Int {
      return option.id
    }
  }
}

struct SettingsView: View {
  
  var rows: [SettingsOption] = [.videoPlaybackSpeed, .downloads, .downloadsQuality, .subtitles]
  
  @Binding var isPresented: Bool
  @State private var settingsOptionsPresented: Bool = false
  @State var selectedOption: SettingsOption = .videoPlaybackSpeed
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        HStack() {
          Rectangle()
            .frame(width: 27, height: 27, alignment: .center)
            .foregroundColor(.clear)
            .padding([.leading], 18)
          
          Spacer()
          
          Text(Constants.settings)
            .font(.uiHeadline)
            .foregroundColor(.appBlack)
            .padding([.top], 20)
          
          Spacer()
          
          Button(action: {
            self.isPresented = false
          }) {
            Image("close")
              .frame(width: 27, height: 27, alignment: .center)
              .padding(.trailing, 18)
              .padding([.top], 20)
              .foregroundColor(.battleshipGrey)
          }
        }
        
        VStack {
          ForEach(0..<self.rows.count) { index in
            TitleDetailView(callback: {
              self.selectedOption = self.rows[index]
              
              // Only navigate to SettingsOptionsView if view isn't a toggle 
              if !self.rows[index].isToggle {
                self.settingsOptionsPresented.toggle()
              } else {
                // Update user defaults for toggle 
                let previousState = self.setToggleState(at: index)
                UserDefaults.standard.set(!previousState,
                                          forKey: self.rows[index].title)
              }
              
            }, title: self.rows[index].title, detail: self.populateDetail(at: index), isToggle: self.rows[index].isToggle, isOn: self.setToggleState(at: index), rightImageName: "carrotRight")
              .frame(height: 46)
              .sheet(isPresented: self.$settingsOptionsPresented) {
                SettingsOptionsView(isPresented: self.$settingsOptionsPresented, isOn: self.setToggleState(at: index), selectedSettingsOption: self.$selectedOption)
            }
          }
        }
        
        Spacer()
        
        Button(action: {
          Guardpost.current.logout()
        }) {
          HStack {
            Rectangle()
              .frame(width: 24, height: 46, alignment: .center)
              .foregroundColor(Color.copper)
            
            Spacer()
            
            Text("Sign Out")
              .font(.uiButtonLabel)
              .background(Color.copper)
              .foregroundColor(.white)
            
            Spacer()
            
            Image("arrowRed")
              .frame(width: 24, height: 24, alignment: .center)
              .background(Color.white)
              .foregroundColor(.copper)
              .cornerRadius(6)
              .padding([.trailing], 10)
          }
          .background(Color.copper)
          .cornerRadius(6)
          .padding([.leading, .trailing], 18)
          .frame(height: 46)
        }
        .padding(.bottom, 42)
        .frame(width: geometry.size.width - (2 * 18), height: 46, alignment: .center)
        .padding([.leading, .trailing], 18)
        
      }
      .frame(width: geometry.size.width, height: geometry.size.height,alignment: .center)
      .background(Color.paleGrey)
      .padding([.top], 20)
    }
  }
  
  private func populateDetail(at index: Int) -> String {
    guard let selectedDetail = UserDefaults.standard.object(forKey: rows[index].title) as? String else {
      if let detail = self.rows[index].detail.detailOptions.first {
        return detail
      } else {
        return ""
      }
    }
    
    return selectedDetail
  }
  
  private func setToggleState(at index: Int) -> Bool {
    return UserDefaults.standard.bool(forKey: rows[index].title)
  }
}
