//
//  FTFileManager.swift
//  Feather
//
//  Created by 이시원 on 2/27/25.
//

import Foundation

actor FTFileManager: Sendable {
  private let cacheURL: URL
  static let shared = FTFileManager()
  private let cacheSizeCalculator: CacheSizeCalculator
  private let fileManager: FileManager = .default
  private var cacheItems: [String: CacheItem] = [:]
  
  init() {
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    self.cacheURL = paths[0].appendingPathComponent("ImageCache")
    cacheSizeCalculator = CacheSizeCalculator(cacheURL: cacheURL)
  }
  
  func readCache(
    fileName: String
  ) async -> (imageURL: URL, eTag: String?, modified: String?)? {
    await cacheItem(for: fileName).read()
  }
  
  @discardableResult
  func create(fileName: String, data: Data?, eTag: String?, modified: String?) async -> URL? {
    await cacheItem(for: fileName).create(
      data: data,
      eTag: eTag,
      modified: modified
    )
  }
  
  @discardableResult
  func create(fileName: String, tempURL: URL, eTag: String?, modified: String?) async -> URL? {
    await cacheItem(for: fileName).create(
      tempURL: tempURL,
      eTag: eTag,
      modified: modified
    )
  }
  
  func remove(fileName: String) async throws {
    try await cacheItem(for: fileName).remove()
    cacheItems[fileName] = nil
  }
  
  func removeAll() async throws {
    if fileManager.fileExists(atPath: cacheURL.toPath()) {
      try fileManager.removeItem(at: cacheURL)
    }
    cacheItems = [:]
    await cacheSizeCalculator.reset()
  }
  
  func getFileCreateDate(fileName: String) async throws -> Date? {
    try await cacheItem(for: fileName).createDate()
  }
  
  func setAttributes(_ attributes: [FileAttributeKey: Date], fileName: String) async throws {
    try await cacheItem(for: fileName).setAttributes(attributes)
  }
  
  func contentsOfDirectory(includingPropertiesForKeys: [URLResourceKey]?) -> [URL]? {
    return try? fileManager.contentsOfDirectory(
      at: cacheURL,
      includingPropertiesForKeys: includingPropertiesForKeys,
      options: []
    )
  }
  
  func directorySize(at url: URL) async throws -> Int? {
    let fileName = url.lastPathComponent
    return try await cacheItem(for: fileName).size()
  }
  
  func getTotalCacheSize() async -> Int {
    await cacheSizeCalculator.totalSize()
  }
}

private extension FTFileManager {
  func cacheItem(for name: String) -> CacheItem {
    if let cacheItem = cacheItems[name] { return cacheItem }
    let cacheItem = CacheItem(cacheURL: cacheURL, name: name, cacheSizeCalculator: cacheSizeCalculator)
    cacheItems[name] = cacheItem
    return cacheItem
  }
}

