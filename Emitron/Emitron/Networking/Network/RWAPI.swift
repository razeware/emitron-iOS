//
//  EmitronAPI.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

typealias HTTPHeaders = [String: String]

enum RWAPIError: Error {
  case requestFailed(Error?, Int)
  case processingError(Error?)
}

struct RWAPI {
  let environment: RWEnvironment
  let session: URLSession
  let authToken: String
  
  // HTTP Headers
  let contentTypeHeader: HTTPHeaders = ["Content-Type": "application/vnd.api+json; charset=utf-8"]
  var additionalHeaders: HTTPHeaders?
  
  init(session: URLSession = URLSession(configuration: .default), environment: RWEnvironment = .prod, authToken: String) {
    self.session = session
    self.environment = environment
    self.authToken = authToken
  }
}
