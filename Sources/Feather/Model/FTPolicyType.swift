//
//  FTPolicyType.swift
//  Feather
//
//  Created by 이시원 on 3/2/25.
//

public enum FTPolicyType {
  case none
  case LRU(maxSize: UInt64)
}
