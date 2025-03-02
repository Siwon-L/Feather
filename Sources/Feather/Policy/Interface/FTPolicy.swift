//
//  FTPolicy.swift
//  Feather
//
//  Created by 이시원 on 3/2/25.
//

protocol FTPolicy: Sendable {
  func execute(deleteHandler: (String) -> Void)
  func updateAccessTime(fileName: String)
}
