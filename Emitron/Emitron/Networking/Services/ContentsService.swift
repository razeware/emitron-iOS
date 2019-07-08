//
//  ContentsService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class ContentsService: Service {
  
  func allContents(parameters: [Parameter], completion: @escaping (_ response: Result<ContentsRequest.Response, RWAPIError>) -> Void) {
    let request = ContentsRequest()
    makeAndProcessRequest(request: request, parameters: parameters, completion: completion)
  }
}
