////
////  EmitronRequest.swift
////  Emitron
////
////  Created by Lea Marolt Sonnenschein on 7/1/19.
////  Copyright © 2019 Razeware. All rights reserved.
////
//
//import Foundation
//
//protocol EmitronRequest {
//  associatedtype Response
//  
//  var method: HTTPMethod { get }
//  var path: String { get }
//  var contentType: String { get }
//  var additionalHeaders: [String: String]? { get }
//  var body: Data? { get }
//  
//  func handle(response: Data) throws -> Response
//}
