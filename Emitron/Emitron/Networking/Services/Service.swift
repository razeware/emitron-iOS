// Copyright (c) 2022 Kodeco Inc

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

protocol Service {
  var networkClient: RWAPI { get }
  var session: URLSession { get }
}

extension Service {
  var isAuthenticated: Bool { !networkClient.authToken.isEmpty }

  @MainActor func makeRequest<Request: Emitron.Request>(
    request: Request,
    parameters: [Parameter] = []
  ) async throws -> Request.Response {
    func prepare<Request: Emitron.Request>(
      request: Request,
      parameters: [Parameter]
    ) throws -> URLRequest {
      let pathURL = networkClient.environment.baseURL.appendingPathComponent(request.path)

      guard var components = URLComponents(
        url: pathURL,
        resolvingAgainstBaseURL: false
      ) else {
        throw URLError(.badURL)
      }

      components.queryItems = parameters.map { .init(name: $0.key, value: $0.value) }

      guard let url = components.url
      else { throw URLError(.badURL) }

      var urlRequest = URLRequest(url: url)
      urlRequest.httpMethod = request.method.rawValue
      // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
      urlRequest.httpBody = request.body

      let authTokenHeader: HTTPHeader = ("Authorization", "Token \(networkClient.authToken)")
      let headers =
        [authTokenHeader, networkClient.contentTypeHeader]
          + [networkClient.additionalHeaders, request.additionalHeaders].joined()
      headers.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

      return urlRequest
    }

    let (data, response) = try await session.data(
      for: try prepare(request: request, parameters: parameters)
    )

    let statusCode = (response as? HTTPURLResponse)?.statusCode
    guard statusCode.map((200..<300).contains) == true
    else { throw RWAPIError.requestFailed(nil, statusCode ?? 0) }

    return try request.handle(response: data)
  }
}
