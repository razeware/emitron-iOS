//
//  EmitronAPI.swift
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
}

enum APIError: Error {
  case requestFailed(Error?, Int)
  case postProcessingFailed(Error?)
}

struct EmitronAPI {
  let environment: EmitronEnvironment
  let session: URLSession
  
  init(session: URLSession = URLSession(configuration: .default), environment: EmitronEnvironment = .prod) {
    self.session = session
    self.environment = environment
  }
  
  func perform<T: EmitronRequest>(request: T, completion: @escaping (Result<T.Response, APIError>) -> Void) {
    let url = environment.baseUrl.appendingPathComponent(request.path)
    var urlRequest = URLRequest(url: url)
    
    urlRequest.addValue(request.contentType, forHTTPHeaderField: "Content-Type")
    if let headers = request.additionalHeaders {
      headers.forEach { key, value in
        urlRequest.addValue(value, forHTTPHeaderField: key)
      }
    }
    
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body
    
    let task = session.dataTask(with: urlRequest) { data, response, error in
      let finishOnMain: (Result<T.Response, APIError>) -> Void = { result in
        DispatchQueue.main.async {
          completion(result)
        }
      }
      
      guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        finishOnMain(.failure(.requestFailed(error, statusCode)))
        return
      }
      
      do {
        let value = try request.handle(response: data ?? Data())
        finishOnMain(.success(value))
      } catch let handleError {
        finishOnMain(.failure(.postProcessingFailed(handleError)))
      }
    }
    task.resume()
  }
}

class SSLAuthHandler: NSObject, URLSessionDelegate {
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.host == "192.168.7.26" {
      let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
      completionHandler(.useCredential, credential)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
}
