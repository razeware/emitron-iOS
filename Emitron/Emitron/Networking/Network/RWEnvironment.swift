//
//  RWEnvironment.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

struct RWEnvironment {
  var baseUrl: URL
}

extension RWEnvironment {
  static let prod = RWEnvironment(baseUrl: URL(string: "https://api.raywenderlich.com/api")!)
}
