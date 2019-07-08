//
//  RemoteEndpoint.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/4/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

public enum ContentType2: String {
  case json = "application/json"
  case xml = "application/xml"
}

public func expected200to300(_ code: Int) -> Bool {
  return code >= 200 && code < 300
}

public struct Endpoint<A> {
  public enum Method {
    case get, post, put, patch
  }
  
  public var request: URLRequest
  var parse: (Data?) -> Result<A, Error>
  var expectedStatusCode: (Int) -> Bool = expected200to300
  
  public func map<B>(_ f: @escaping (A) -> B) -> Endpoint<B> {
    return Endpoint<B>(request: request, expectedStatusCode: expectedStatusCode, parse: { value in
      self.parse(value).map(f)
    })
  }
  
  public func compactMap<B>(_ transform: @escaping (A) -> Result<B, Error>) -> Endpoint<B> {
    return Endpoint<B>(request: request, expectedStatusCode: expectedStatusCode, parse: { data in
      self.parse(data).flatMap(transform)
    })
  }
  
  public init(_ method: Method, url: URL, accept: ContentType2? = nil, ContentType2: ContentType2? = nil, body: Data? = nil, headers: [String:String] = [:], expectedStatusCode: @escaping (Int) -> Bool = expected200to300, timeOutInterval: TimeInterval = 10, query: [String:String] = [:], parse: @escaping (Data?) -> Result<A, Error>) {
    var comps = URLComponents(string: url.absoluteString)!
    comps.queryItems = comps.queryItems ?? []
    comps.queryItems!.append(contentsOf: query.map { URLQueryItem(name: $0.0, value: $0.1) })
    request = URLRequest(url: comps.url!)
    if let a = accept {
      request.setValue(a.rawValue, forHTTPHeaderField: "Accept")
    }
    if let ct = ContentType2 {
      request.setValue(ct.rawValue, forHTTPHeaderField: "Content-Type")
    }
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    request.timeoutInterval = timeOutInterval
    request.httpMethod = method.string
    
    // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
    request.httpBody = body
    
    self.expectedStatusCode = expectedStatusCode
    self.parse = parse
  }
  
  public init(request: URLRequest, expectedStatusCode: @escaping (Int) -> Bool = expected200to300, parse: @escaping (Data?) -> Result<A, Error>) {
    self.request = request
    self.expectedStatusCode = expectedStatusCode
    self.parse = parse
  }
}

extension Endpoint: CustomStringConvertible {
  public var description: String {
    let data = request.httpBody ?? Data()
    return "\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "<no url>") \(String(data: data, encoding: .utf8) ?? "")"
  }
}

extension Endpoint.Method {
  var string: String {
    switch self {
    case .get: return "GET"
    case .post: return "POST"
    case .put: return "PUT"
    case .patch: return "PATCH"
    }
  }
}

extension Endpoint where A == () {
  public init(_ method: Method, url: URL, accept: ContentType2? = nil, headers: [String:String] = [:], expectedStatusCode: @escaping (Int) -> Bool = expected200to300, query: [String:String] = [:]) {
    self.init(method, url: url, accept: accept, headers: headers, expectedStatusCode: expectedStatusCode, query: query, parse: { _ in .success(()) })
  }
  
  public init<B: Codable>(json method: Method, url: URL, accept: ContentType2? = .json, body: B, headers: [String:String] = [:], expectedStatusCode: @escaping (Int) -> Bool = expected200to300, query: [String:String] = [:]) {
    let b = try! JSONEncoder().encode(body)
    self.init(method, url: url, accept: accept, ContentType2: .json, body: b, headers: headers, expectedStatusCode: expectedStatusCode, query: query, parse: { _ in .success(()) })
  }
}

extension Endpoint where A: Decodable {
  public init(json method: Method, url: URL, accept: ContentType2 = .json, headers: [String: String] = [:], expectedStatusCode: @escaping (Int) -> Bool = expected200to300, query: [String: String] = [:], decoder: JSONDecoder? = nil) {
    let d = decoder ?? JSONDecoder()
    self.init(method, url: url, accept: accept, body: nil, headers: headers, expectedStatusCode: expectedStatusCode, query: query) { data in
      return Result {
        guard let dat = data else { throw NoDataError() }
        return try d.decode(A.self, from: dat)
      }
    }
  }
  
  public init<B: Codable>(json method: Method, url: URL, accept: ContentType2 = .json, body: B? = nil, headers: [String: String] = [:], expectedStatusCode: @escaping (Int) -> Bool = expected200to300, query: [String: String] = [:]) {
    let b = body.map { try! JSONEncoder().encode($0) }
    self.init(method, url: url, accept: accept, ContentType2: .json, body: b, headers: headers, expectedStatusCode: expectedStatusCode, query: query) { data in
      return Result {
        guard let dat = data else { throw NoDataError() }
        return try JSONDecoder().decode(A.self, from: dat)
      }
    }
  }
}

public struct NoDataError: Error {}
public struct UnknownError: Error {}
public struct WrongStatusCodeError: Error {
  public let statusCode: Int
}

extension URLSession {
  @discardableResult
  public func load<A>(_ e: Endpoint<A>, onComplete: @escaping (Result<A, Error>) -> ()) -> URLSessionDataTask {
    let r = e.request
    let task = dataTask(with: r, completionHandler: { data, resp, err in
      guard let h = resp as? HTTPURLResponse else {
        onComplete(.failure(UnknownError()))
        return
      }
      
      guard e.expectedStatusCode(h.statusCode) else {
        onComplete(.failure(WrongStatusCodeError(statusCode: h.statusCode)))
        return
      }
      
      onComplete(e.parse(data))
    })
    task.resume()
    return task
  }
  
  public func onDelegateQueue(_ f: @escaping () -> ()) {
    self.delegateQueue.addOperation(f)
  }
}
