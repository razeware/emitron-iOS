//
//  VideosRequest.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/2/19.
//  Copyright © 2019 Razeware. All rights reserved.
//


import Foundation
import SwiftyJSON

// Might never be constructing video requests

struct VideoRequest {
  static func showVideo(id: String) -> ShowVideoRequest {
    return ShowVideoRequest(id: id)
  }
  
  static func getVideoStream(id: String) -> StreamVideoRequest {
    return StreamVideoRequest(id: id)
  }
  
  static func getVideoDownload(id: String) -> DownloadVideoRequest {
    return DownloadVideoRequest(id: id)
  }
}

struct ShowVideoRequest: Request {
  typealias Response = Video
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/videos\(id)" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  private var id: String
  
  init(id: String) {
    self.id = id
  }
  
  func handle(response: Data) throws -> Video {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let videos = doc.data.compactMap{ Video($0, metadata: nil) }
    return videos.first!
  }
}

struct StreamVideoRequest: Request {
  typealias Response = Attachment
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/videos\(id)/stream" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  private var id: String
  
  init(id: String) {
    self.id = id
  }
  
  func handle(response: Data) throws -> Attachment {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let attachments = doc.data.compactMap{ Attachment($0, metadata: nil) }
    return attachments.first!
  }
}

struct DownloadVideoRequest: Request {
  // It contains two Attachment objects, one for the HD file and one for the SD file.
  typealias Response = [Attachment]
  
  var method: HTTPMethod { return .GET }
  var path: String { return "/videos\(id)/download" }
  var additionalHeaders: [String : String]?
  var body: Data? { return nil }
  
  private var id: String
  
  init(id: String) {
    self.id = id
  }
  
  func handle(response: Data) throws -> [Attachment] {
    let json = try JSON(data: response)
    let doc = JSONAPIDocument(json)
    let attachments = doc.data.compactMap{ Attachment($0, metadata: nil) }
    return attachments
  }
}
