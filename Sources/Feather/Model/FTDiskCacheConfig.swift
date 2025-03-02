//
//  FTDiskCacheConfig.swift
//  Feather
//
//  Created by 이시원 on 2/28/25.
//

import Foundation

public struct FTDiskCacheConfig: Sendable {
  let timeOut: TimeInterval
  let policy: FTPolicy?
  
  public init(timeOut: TimeInterval = FTConstant.defaultTimeOut, policy: FTPolicyType = .none) {
    self.timeOut = timeOut
    switch policy {
    case .none:
      self.policy = nil
    case let .LRU(maxSize):
      self.policy = LRUPolicy(maxSize: maxSize)
    }
  }
}

