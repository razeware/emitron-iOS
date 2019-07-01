//
//  ContentView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 6/29/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Combine
import SwiftUI

// BindableObject needs import Combine
class DataSource: BindableObject {
  // send Voic, and Never send errors
  let didChange = PassthroughSubject<Void, Never>()
  var pictures = [String]()
  
  init() {
    let fm = FileManager.default
    
    if let path = Bundle.main.resourcePath,
      let items = try? fm.contentsOfDirectory(atPath: path) {
      for item in items {
        if item.hasPrefix("nssl") {
          pictures.append(item)
        }
      }
    }
    didChange.send(())
  }
}

struct DetailView: View {
  @State private var hidesNavigationBar = false
  var selectedImage: String
  
  var body: some View {
    let img = UIImage(named: selectedImage)!
    return Image(uiImage: img)
      .resizable()
      // .aspectRatio(contentMode: .fit) SwiftUI not working
      .aspectRatio(1024/768, contentMode: .fit)
      .navigationBarTitle(Text(selectedImage), displayMode: .inline)
      .navigationBarHidden(hidesNavigationBar)
      .tapAction {
        // Image was tapped
        self.hidesNavigationBar.toggle()
    }
  }
}

struct StaticListView: View {
  
  //@ObjectBinding - don't reload it again and again
  @ObjectBinding var dataSource = DataSource()
  
  var body: some View {
    NavigationView {
      List(dataSource.pictures.identified(by: \.self)) { picture in
        NavigationButton(destination: DetailView(selectedImage: picture), isDetail: true) {
          Text(picture)
        }
      }.navigationBarTitle(Text("Emitron"))
    }
  }
}

#if DEBUG
struct StaticListView_Previews : PreviewProvider {
  static var previews: some View {
    StaticListView()
  }
}
#endif
