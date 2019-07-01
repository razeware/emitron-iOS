//
//  RWAPI.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation
import Alamofire

enum RWEnvironment {
  case production
  
  var host: String {
    return "https://api.raywenderlich.com/api"
  }
  
  var url: URL { return URL(string: host)! }
  
  var defaultHeaders: HTTPHeaders {
    return [:]
  }
}

class RWAPI: NSObject {
  private let environment: RWEnvironment
  private var hasSessionExpired: Bool {
    return false
  }
  private var requestHeaders: HTTPHeaders
  
  init(environment: RWEnvironment, headers: HTTPHeaders = [:], authToken: String?) {
    self.environment = environment
    self.requestHeaders = headers
  }
  
}
