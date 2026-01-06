//
//  CacheSizeCalculator.swift
//  Feather
//
//  Created by 이시원 on 1/7/26.
//

import Foundation

actor CacheSizeCalculator: Sendable {
  private var _totalSize: Int?
  private let fileManager: FileManager = .default
  private let cacheURL: URL
  
  init(cacheURL: URL) {
    self.cacheURL = cacheURL
  }
  
  func totalSize() -> Int {
    guard let _totalSize else {
      let totalSize = calculateTotalSize()
      _totalSize = totalSize
      return totalSize
    }
    return _totalSize
  }
  
  func add(_ value: Int) {
    _totalSize = totalSize() + value
  }
  
  func subtract(_ value: Int) {
    _totalSize = totalSize() - value
  }
  
  func reset() {
    _totalSize = 0
  }
}

private extension CacheSizeCalculator {
  func directorySize(at url: URL) throws -> Int? {
    return try fileManager.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: [.fileSizeKey],
      options: [.skipsHiddenFiles]
    ).reduce(0, { totalSize, file in
      guard let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return totalSize }
      return totalSize + fileSize
    })
  }
  
  func calculateTotalSize() -> Int {
    guard let files = try? fileManager.contentsOfDirectory(
      at: cacheURL,
      includingPropertiesForKeys: [.fileSizeKey],
      options: []
    ) else { return 0 }
    return files.reduce(0) { totalSize, file in
      let fileSize = (try? self.directorySize(at: file)) ?? 0
      return totalSize + fileSize
    }
  }
}
