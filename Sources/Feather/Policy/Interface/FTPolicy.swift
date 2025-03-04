//
//  FTPolicy.swift
//  Feather
//
//  Created by 이시원 on 3/2/25.
//

import Foundation

protocol FTPolicy: Sendable {
  func execute() async -> [URL]
  func updateAccessTime(fileName: String, date: Date) async
}
