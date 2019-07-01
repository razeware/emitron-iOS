//
//  EmitronEnvironment.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

struct EmitronEnvironment {
  var baseUrl: URL
}

extension EmitronEnvironment {
  static let prod = EmitronEnvironment(baseUrl: URL(string: "https://api.raywenderlich.com/api")!)
}
