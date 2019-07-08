//
//  BookmarksService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class BookmarksService: Service {
  
  func bookmarks(parameters: [Parameter]? = nil, completion: @escaping (_ response: Result<GetBookmarksRequest.Response, RWAPIError>) -> Void) {
    let request = BookmarksRequest.getAll
    makeAndProcessRequest(request: request, parameters: parameters, completion: completion)
  }
  
  func deleteBookmark(for id: String, completion: @escaping (_ response: Result<DeleteBookmarkRequest.Response, RWAPIError>) -> Void) {
    let request = BookmarksRequest.deleteBookmark(id: id)
    makeAndProcessRequest(request: request, completion: completion)
  }
}
