//
//  Service.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Service {
  
  let networkClient: RWAPI
  let session: URLSession
  
  init(client: RWAPI) {
    self.networkClient = client
    self.session = URLSession(configuration: .default)
  }
  
  func makeAndProcessRequest<R: Request>(request: R, completion: @escaping (Result<R.Response, RWAPIError>) -> Void) {
    
    let handleResponse: (Result<R.Response, RWAPIError>) -> Void = { result in
      DispatchQueue.main.async {
        completion(result)
      }
    }
    
    let urlRequest = prepare(request: request)
    let task = session.dataTask(with: urlRequest) { data, response, error in
      
      guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        handleResponse(.failure(.requestFailed(error, statusCode)))
        return
      }
      
      do {
        let value = try request.handle(response: data ?? Data())
        handleResponse(.success(value))
      } catch let handleError {
        handleResponse(.failure(.processingError(handleError)))
      }
    }
    
    task.resume()
  }
  
  func prepare<R: Request>(request: R) -> URLRequest {
    let url = networkClient.environment.baseUrl.appendingPathComponent(request.path)
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpBody = request.body
    urlRequest.httpMethod = request.method.rawValue
    
    let authTokenHeader: HTTPHeaders = ["Authorization": "Token \(networkClient.authToken)"]
    let headers = networkClient.contentTypeHeader.merged(networkClient.additionalHeaders,
                                                         request.additionalHeaders,
                                                         authTokenHeader)
    headers.forEach{ urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

    return urlRequest
  }
}
