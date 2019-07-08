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
  
  func makeAndProcessRequest<R: Request>(request: R, parameters: [Parameter]? = nil, completion: @escaping (Result<R.Response, RWAPIError>) -> Void) {
    
    let handleResponse: (Result<R.Response, RWAPIError>) -> Void = { result in
      DispatchQueue.main.async {
        completion(result)
      }
    }
    
    guard let urlRequest = prepare(request: request, parameters: parameters) else { return }
    
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
  
  func prepare<R: Request>(request: R, parameters: [Parameter]?) -> URLRequest? {
    let pathURL = networkClient.environment.baseUrl.appendingPathComponent(request.path)
    
    var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false)
    
    if let parames = parameters {
      let queryItems = parames.map { parameter -> URLQueryItem in
        let queryItem = URLQueryItem(name: parameter.key, value: parameter.value)
        return queryItem
      }

      components?.queryItems = queryItems
    }
    
    guard let url = components?.url else { return nil }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method.rawValue
    // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
    urlRequest.httpBody = request.body
    
    let authTokenHeader: HTTPHeaders = ["Authorization": "Token \(networkClient.authToken)"]
    let headers = networkClient.contentTypeHeader.merged(networkClient.additionalHeaders,
                                                         request.additionalHeaders,
                                                         authTokenHeader)
    headers.forEach{ urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

    return urlRequest
  }
}
