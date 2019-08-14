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

enum SettingsOptions: Identifiable {
  case videoPlaybackSpeed, downloads, downloadsQuality, subtitles
  
  var id: Int {
    switch self {
      case .videoPlaybackSpeed: return 1
      case .downloads: return 2
      case .downloadsQuality: return 3
      case .subtitles: return 4
    }
  }
  
  var title: String {
    switch self {
      case .videoPlaybackSpeed: return "Video Playback Speed"
      case .downloads: return "Downloads (Wifi only)"
      case .downloadsQuality: return "Downloads Quality"
      case .subtitles: return "Subtitles"
    }
  }
  
  var detail: [String] {
    switch self {
      case .videoPlaybackSpeed: return ["1.0", "1.5", "2.0"]
      case .downloads: return ["Yes", "No"]
      case .downloadsQuality: return ["HD", "SD"]
      case .subtitles: return ["Yes", "No"]
    }
  }
}

struct SettingsView: View {
  
  var rows: [SettingsOptions] = [.videoPlaybackSpeed, .downloads, .downloadsQuality, .subtitles]
  
  @Binding var isPresented: Bool
  
  var body: some View {
    
    GeometryReader { geometry in
      
      VStack {
        
        HStack() {
          
          Rectangle()
            .frame(width: 27, height: 27, alignment: .center)
            .foregroundColor(.clear)
            .padding([.leading], 18)
          
          Spacer()
          
          Text("Settings")
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
          ForEach(self.rows, id: \.id) { row in
            TitleDetailView(callback: { row in
              
              print("SHOW VIEW")
              
            }, row: row)
              .frame(height: 46)
          }
        }
        
        Spacer()
        
        Button(action: {
          
          print("SIGN OUT")
          
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
}
