////
////  EmitronAPI.swift
////  Emitron
////
////  Created by Lea Marolt Sonnenschein on 7/1/19.
////  Copyright © 2019 Razeware. All rights reserved.
////
//
//import Foundation
//
//enum HTTPMethod: String {
//  case GET
//  case POST
//  case PUT
//}
//
//enum APIError: Error {
//  case requestFailed(Error?, Int)
//  case postProcessingFailed(Error?)
//}
//
//struct EmitronAPI {
//  let environment: EmitronEnvironment
//  let session: URLSession
//  
//  init(session: URLSession = URLSession(configuration: .default, delegate: EmitronAPI.sslAuthHandler, delegateQueue: nil), environment: EmitronEnvironment = .prod) {
//    //    init(session: URLSession = .shared, environment: APIEnvironment = .prod) {
//    self.session = session
//    self.environment = environment
//  }
//  
//  func perform<T: EmitronRequest>(request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
//    let url = environment.baseUrl.appendingPathComponent(request.path)
//    var urlRequest = URLRequest(url: url)
//    
//    urlRequest.addValue(request.contentType, forHTTPHeaderField: "Content-Type")
//    if let headers = request.additionalHeaders {
//      headers.forEach { key, value in
//        urlRequest.addValue(value, forHTTPHeaderField: key)
//      }
//    }
//    if let user = currentUser?.id, let password = currentUser?.password {
//      let auth = "\(user):\(password)"
//      let authString = auth.data(using: .utf8)!.base64EncodedString()
//      urlRequest.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
//    }
//    
//    urlRequest.httpMethod = request.method.rawValue
//    urlRequest.httpBody = request.body
//    
//    let task = session.dataTask(with: urlRequest) { data, response, error in
//      let finishOnMain: (Result<T.Response, APIError>) -> Void = { result in
//        DispatchQueue.main.async {
//          completion(result)
//        }
//      }
//      guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
//        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
//        finishOnMain(.failure(.requestFailed(error, statusCode)))
//        return
//      }
//      
//      do {
//        let value = try request.handle(response: data ?? Data())
//        finishOnMain(.success(value))
//      } catch let handleError {
//        finishOnMain(.failure(.postProcessingFailed(handleError)))
//      }
//    }
//    task.resume()
//  }
//}
