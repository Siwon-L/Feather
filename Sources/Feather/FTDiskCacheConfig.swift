//
//  FTDiskCacheConfig.swift
//  Feather
//
//  Created by 이시원 on 2/28/25.
//

import Foundation

public struct FTDiskCacheConfig: Sendable, Equatable {
  public let timeOut: TimeInterval
  
  public init(timeOut: TimeInterval) {
    self.timeOut = timeOut
  }
}
