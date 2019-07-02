//
//  Download.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

class Download {
  
  var video: Video
  var task: URLSessionDownloadTask?
  var isDownloading: Bool = false
  var resumeData: Data?
  var progress: Double = 0
  
  init(video: Video) {
    self.video = video
  }
}
