//
//  ContentView.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/4/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import SwiftUI
import Combine

final class Resource<A>: BindableObject {
  let didChange = PassthroughSubject<A?, Never>()
  let endpoint: Endpoint<A>
  var value: A? {
    didSet {
      DispatchQueue.main.async {
        self.didChange.send(self.value)
      }
    }
  }
  init(endpoint: Endpoint<A>) {
    self.endpoint = endpoint
    reload()
  }
  func reload() {
    URLSession.shared.load(endpoint) { result in
      self.value = try? result.get()
    }
  }
}

//struct ContentView : View {
//  @ObjectBinding var user = Resource(endpoint: userInfo(login: "objcio"))
//  var body: some View {
//    Group {
//      if user.value == nil {
//        Text("Loading...")
//      } else {
//        VStack {
//          Text(user.value!.name).bold()
//          Text(user.value!.location ?? "")
//        }
//      }
//    }
//  }
//}
//
//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif
