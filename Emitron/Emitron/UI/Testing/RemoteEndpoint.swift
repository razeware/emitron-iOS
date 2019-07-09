/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

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

  public func map<B>(_ function: @escaping (A) -> B) -> Endpoint<B> {
    return Endpoint<B>(request: request, expectedStatusCode: expectedStatusCode) { value in
      self.parse(value).map(function)
    }
  }

  public func compactMap<B>(_ transform: @escaping (A) -> Result<B, Error>) -> Endpoint<B> {
    return Endpoint<B>(request: request, expectedStatusCode: expectedStatusCode) { data in
      self.parse(data).flatMap(transform)
    }
  }

  public init(_ method: Method,
              url: URL,
              accept: ContentType2? = nil,
              ContentType2: ContentType2? = nil,
              body: Data? = nil,
              headers: [String: String] = [:],
              expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
              timeOutInterval: TimeInterval = 10,
              query: [String: String] = [:],
              parse: @escaping (Data?) -> Result<A, Error>) {
    var comps = URLComponents(string: url.absoluteString)!
    comps.queryItems = comps.queryItems ?? []
    comps.queryItems!.append(contentsOf: query.map { URLQueryItem(name: $0.0, value: $0.1) })
    request = URLRequest(url: comps.url!)
    if let accept = accept {
      request.setValue(accept.rawValue, forHTTPHeaderField: "Accept")
    }

    if let contentType = ContentType2 {
      request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
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
    case .get:
      return "GET"
    case .post:
      return "POST"
    case .put:
      return "PUT"
    case .patch:
      return "PATCH"
    }
  }
}

extension Endpoint where A == () {

  public init(_ method: Method,
              url: URL,
              accept: ContentType2? = nil,
              headers: [String: String] = [:],
              expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
              query: [String: String] = [:]) {
    self.init(method,
              url: url,
              accept: accept,
              headers: headers,
              expectedStatusCode: expectedStatusCode,
              query: query) { _ in .success(()) }
  }

  public init<B: Codable>(json method: Method,
                          url: URL,
                          accept: ContentType2? = .json,
                          body: B,
                          headers: [String: String] = [:],
                          expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
                          query: [String: String] = [:]) {
    let b = try! JSONEncoder().encode(body)
    self.init(method,
              url: url,
              accept: accept,
              ContentType2: .json,
              body: b,
              headers: headers,
              expectedStatusCode: expectedStatusCode,
              query: query) { _ in .success(()) }
  }
}

extension Endpoint where A: Decodable {
  public init(json method: Method,
              url: URL,
              accept: ContentType2 = .json,
              headers: [String: String] = [:],
              expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
              query: [String: String] = [:],
              decoder: JSONDecoder? = nil) {
    let d = decoder ?? JSONDecoder()
    self.init(method,
              url: url,
              accept: accept,
              body: nil,
              headers: headers,
              expectedStatusCode: expectedStatusCode,
              query: query) { data in
      Result {
        guard let dat = data else {
          throw NoDataError()
        }

        return try d.decode(A.self, from: dat)
      }
    }
  }

  public init<B: Codable>(json method: Method,
                          url: URL,
                          accept: ContentType2 = .json,
                          body: B? = nil,
                          headers: [String: String] = [:],
                          expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
                          query: [String: String] = [:]) {
    let b = body.map { try! JSONEncoder().encode($0) }
    self.init(method,
              url: url,
              accept: accept,
              ContentType2: .json,
              body: b,
              headers: headers,
              expectedStatusCode: expectedStatusCode,
              query: query) { data in
      Result {
        guard let dat = data else {
          throw NoDataError()
        }

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
  public func load<A>(_ endpoint: Endpoint<A>, onComplete: @escaping (Result<A, Error>) -> Void) -> URLSessionDataTask {
    let request = endpoint.request
    let task = dataTask(with: request) { data, resp, _ in
      guard let response = resp as? HTTPURLResponse else {
        onComplete(.failure(UnknownError()))
        return
      }

      guard endpoint.expectedStatusCode(response.statusCode) else {
        onComplete(.failure(WrongStatusCodeError(statusCode: response.statusCode)))
        return
      }

      onComplete(endpoint.parse(data))
    }

    task.resume()

    return task
  }

  public func onDelegateQueue(_ function: @escaping () -> Void) {
    self.delegateQueue.addOperation(function)
  }
}
