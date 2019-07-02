//
//  Attachment.swift
//  Emitron
//
//  Created by Lea Marolt Sonnenschein on 7/1/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import Foundation

enum AttachmentKind: String {
  case stream
  case sdVideoFile = "sd_video_file"
  case hdVideoFile = "hd_video_file"
}

class Attachment {
  
  var id: String?
  var url: URL?
  var kind: AttachmentKind?
  
  init?(_ jsonResource: JSONAPIResource, metadata: [String: Any]?) {
    
    self.id = jsonResource.id
    self.url = URL(string: (jsonResource["name"] as? String) ?? "")
    
    if let attachmentKind = AttachmentKind(rawValue: jsonResource["kind"] as? String ?? "") {
      self.kind = attachmentKind
    }
  }
}
