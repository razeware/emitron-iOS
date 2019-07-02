//
//  Request.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
  case GET
  case POST
  case PUT
  case DELETE
  case PATCH
}

typealias Parameters = [String: String]

protocol Request {
  associatedtype Response
  
  var method: HTTPMethod { get }
  var path: String { get }
  var additionalHeaders: [String: String]? { get }
  var body: Data? { get }
  var parameters: Parameters? { get }
  
  func handle(response: Data) throws -> Response
}

// Default implementation to .GET
extension Request {
  var method: HTTPMethod { return .GET }
  var body: Data? { return nil }
}
