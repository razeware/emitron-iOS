//
//  CardView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI

struct CardView : View {
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        VStack {
          Text("Advanced Swift: Values and References")
            .frame(width: 214, height: 48, alignment: .topLeading)
            .font(.uiTitle4)
            .lineLimit(2)
          Text("iOS & Swift")
            .frame(width: 214, height: 16, alignment: .leading)
            .font(.uiCaption)
            .lineLimit(1)
            .foregroundColor(.battleshipGrey)
        }
        
        Image("SwiftSquare")
          .resizable()
          .frame(width: 60, height: 60, alignment: .topTrailing)
          .cornerRadius(6)
      }
      
      Text("Get up and running fast with the recently announced and pre-alpha Jetpack Compose toolkit.")
        .frame(width: 214, height: 75, alignment: .topLeading)
        .font(.uiCaption)
        .lineLimit(4)
        .foregroundColor(.battleshipGrey)
      
      HStack {
        Text("Today * Screencast (49 min)")
          .frame(width: 214, height: 16, alignment: .leading)
          .font(.uiCaption)
          .lineLimit(1)
          .foregroundColor(.battleshipGrey)
        Image("download")
      }
    
    }
      .frame(width: 340, height: 185, alignment: .center)
      .padding()
      .background(Color.paleBlue)
      .cornerRadius(6)
      .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 2)
  }
}

#if DEBUG
struct CardView_Previews : PreviewProvider {
  static var previews: some View {
    CardView()
  }
}
#endif
