//
//  VideosService.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class VideosService: Service {
  
  func video(for id: String, completion: @escaping (_ response: Result<ShowVideoRequest.Response, RWAPIError>) -> Void) {
    let request = ShowVideoRequest(id: id)
    makeAndProcessRequest(request: request, completion: completion)
  }
  
  func getVideoStream(for id: String, completion: @escaping (_ response: Result<StreamVideoRequest.Response, RWAPIError>) -> Void) {
    let request = StreamVideoRequest(id: id)
    makeAndProcessRequest(request: request, completion: completion)
  }
  
  func getVideoDownload(for id: String, completion: @escaping (_ response: Result<DownloadVideoRequest.Response, RWAPIError>) -> Void) {
    let request = DownloadVideoRequest(id: id)
    makeAndProcessRequest(request: request, completion: completion)
  }
}
