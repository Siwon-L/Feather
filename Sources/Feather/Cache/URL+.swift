//
//  URL+.swift
//  Feather
//
//  Created by 이시원 on 1/7/26.
//

import Foundation

extension URL {
  func append(path: String) -> URL {
    if #available(iOS 16.0, *) {
      return self.appending(path: path)
    } else {
      return self.appendingPathComponent(path)
    }
  }
  
  func toPath() -> String {
    if #available(iOS 16.0, *) {
      return self.path()
    } else {
      return self.path
    }
  }
}
