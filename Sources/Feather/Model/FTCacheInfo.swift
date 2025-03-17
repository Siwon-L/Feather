//
//  FTCacheInfo.swift
//  Feather
//
//  Created by 이시원 on 2/28/25.
//

import Foundation

struct FTCacheInfo {
  let imageURL: URL?
  let imageData: Data?
  let eTag: String?
  let modified: String?
  
  init(imageURL: URL? = nil, imageData: Data? = nil, eTag: String?, modified: String?) {
    self.imageURL = imageURL
    self.imageData = imageData
    self.eTag = eTag
    self.modified = modified
  }
}
