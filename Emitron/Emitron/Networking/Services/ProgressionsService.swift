//
//  ProgressionsService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class ProgressionsService: Service {
  
  func progressions(parameters: [Parameter]? = nil, completion: @escaping (_ response: Result<ProgressionsRequest.Response, RWAPIError>) -> Void) {
    let request = ProgressionsRequest.getAll
    makeAndProcessRequest(request: request, parameters: parameters, completion: completion)
  }
}
