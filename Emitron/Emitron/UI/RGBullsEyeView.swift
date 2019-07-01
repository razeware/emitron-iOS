//
//  RGBullsEyeView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct RGBullsEyeView : View {
  let rTarget = Double.random(in: 0..<1)
  let gTarget = Double.random(in: 0..<1)
  let bTarget = Double.random(in: 0..<1)
  
  // THE UI should update when this one changes
  @State var rGuess: Double
  @State var gGuess: Double
  @State var bGuess: Double
  
  @State var showAlert = false
  
  func computeScore() -> Int {
    let rDiff = rGuess - rTarget
    let gDiff = gGuess - gTarget
    let bDiff = bGuess - bTarget
    
    let diff = sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff)
    return Int((1.0 - diff) * 100.0 + 0.5)
  }
  
  var body: some View {
    VStack {
      HStack {
        
        // Target color block
        VStack {
          Rectangle().foregroundColor(Color(red: rTarget, green: gTarget, blue: bTarget))
          Text("Match this color").font(.uiTitle1)
        }
        
        // Guess color block
        VStack {
          Rectangle().foregroundColor(Color(red: rGuess, green: gGuess, blue: bGuess))
          HStack {
            Text("R: \(Int(rGuess * 255.0))")
            Text("G: \(Int(gGuess * 255.0))")
            Text("B: \(Int(bGuess * 255.0))")
          }
        }
      }
      
      Button(action: {
        self.showAlert = true
      }) {
        Text("Hit me!")
        }.presentation($showAlert) {
          Alert(title: Text("Your Score: "), message: Text("\(computeScore())"))
      }
      
      VStack {
        ColorSlider(value: $rGuess, textColor: .red)
        ColorSlider(value: $gGuess, textColor: .green)
        ColorSlider(value: $bGuess, textColor: .blue)
      }
    }
  }
}

#if DEBUG
struct RGBullsEyeView_Previews : PreviewProvider {
  static var previews: some View {
    RGBullsEyeView(rGuess: 0.5, gGuess: 0.5, bGuess: 0.5)
  }
}
#endif

struct ColorSlider : View {
  
  @Binding var value: Double
  var textColor: Color
  
  var body: some View {
    return HStack {
      Text("0").color(textColor)
      Slider(value: $value, from: 0.0, through: 1.0)
      Text("255").color(textColor)
      }.padding()
  }
}
