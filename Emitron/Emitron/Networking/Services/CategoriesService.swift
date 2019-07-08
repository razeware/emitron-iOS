//
//  CategoriesService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class CategoriesService: Service {
  
  func allCategories(completion: @escaping (_ response: Result<CategoriesRequest.Response, RWAPIError>) -> Void) {
    let request = CategoriesRequest.getAll
    makeAndProcessRequest(request: request, completion: completion)
  }
}
