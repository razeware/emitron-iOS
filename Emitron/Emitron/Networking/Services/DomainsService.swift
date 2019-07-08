//
//  DomainsService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class DomainsService: Service {
  
  func allDomains(completion: @escaping (_ response: Result<DomainsRequest.Response, RWAPIError>) -> Void) {
    let request = DomainsRequest.getAll
    makeAndProcessRequest(request: request, completion: completion)
  }
}
