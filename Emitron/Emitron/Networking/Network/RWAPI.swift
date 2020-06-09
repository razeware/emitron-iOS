// Copyright (c) 2019 Razeware LLC
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

import class Foundation.URLSession

typealias HTTPHeaders = [String: String]
typealias HTTPHeader = HTTPHeaders.Element

enum RWAPIError: Error {
  case requestFailed(Error?, Int)
  case processingError(Error?)
  case responseMissingRequiredMeta(field: String?)
  case responseHasIncorrectNumberOfElements
  case noData

  var localizedDescription: String {
    switch self {
    case .requestFailed(let error, let statusCode):
      return "RWAPIError::RequestFailed[Status: \(statusCode) | Error: \(error?.localizedDescription ?? "UNKNOWN")]"
    case .processingError(let error):
      return "RWAPIError::ProcessingError[Error: \(error?.localizedDescription ?? "UNKNOWN")]"
    case .responseMissingRequiredMeta(field: let field):
      return "RWAPIError::ResponseMissingRequiredMeta[Field: \(field ?? "UNKNOWN")]"
    case .responseHasIncorrectNumberOfElements:
      return "RWAPIError::ResponseHasIncorrectNumberOfElements"
    case .noData:
      return "RWAPIError::NoData"
    }
  }
}

struct RWAPI {

  // MARK: - Properties
  let environment: RWEnvironment
  let session: URLSession
  let authToken: String

  // MARK: - HTTP Headers
  let contentTypeHeader: HTTPHeader = ("Content-Type", "application/vnd.api+json; charset=utf-8")
  var additionalHeaders: HTTPHeaders = ["RW-App-Token": Configuration.appToken]

  // MARK: - Initializers
  init(session: URLSession = URLSession(configuration: .default),
       environment: RWEnvironment = .prod,
       authToken: String) {
    self.session = session
    self.environment = environment
    self.authToken = authToken
  }
}
