//
//  BookmarksService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class BookmarksService: Service {
  
  func allBookmarks(completion: @escaping (_ response: Result<GetBookmarksRequest.Response, RWAPIError>) -> Void) {
    let request = GetBookmarksRequest()
    
  }
}
