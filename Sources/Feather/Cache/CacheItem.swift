//
//  CacheItem.swift
//  Feather
//
//  Created by 이시원 on 1/7/26.
//

import Foundation

actor CacheItem: Sendable {
  private let cacheURL: URL
  private let name: String
  private let cacheSizeCalculator: CacheSizeCalculator
  private let fileManager: FileManager = .default
  
  init(cacheURL: URL, name: String, cacheSizeCalculator: CacheSizeCalculator) {
    self.cacheURL = cacheURL
    self.name = name
    self.cacheSizeCalculator = cacheSizeCalculator
  }
  
  func read() -> (imageURL: URL, eTag: String?, modified: String?)? {
    let destination = cacheURL.append(path: name)
    guard fileManager.fileExists(atPath: destination.path) else { return nil }
    let imageURL = destination.append(path: "image")
    let eTag = try? String(contentsOf: destination.append(path: "eTag.txt"), encoding: .utf8)
    let modified = try? String(contentsOf: destination.append(path: "modified.txt"), encoding: .utf8)
    return (imageURL, eTag, modified)
  }
  
  func create(tempURL: URL, eTag: String?, modified: String?) async -> URL? {
    let destination = cacheURL.append(path: name)
    guard createCacheItemDirectory(destination: destination) else { return destination.append(path: "image") }
    let path = destination.toPath()
    createETagAndModifiedFile(path: path, eTag: eTag, modified: modified)
    let imageFileURL = URL(fileURLWithPath: path + "/image")
    do {
      try fileManager.copyItem(at: tempURL, to: imageFileURL)
      let createdSize = (try? size()) ?? 0
      await cacheSizeCalculator.add(createdSize)
      return imageFileURL
    } catch {
      return nil
    }
  }
  
  func create(data: Data?, eTag: String?, modified: String?) async -> URL? {
    let destination = cacheURL.append(path: name)
    guard createCacheItemDirectory(destination: destination) else { return destination.append(path: "image") }
    let path = destination.toPath()
    createETagAndModifiedFile(path: path, eTag: eTag, modified: modified)
    let imagePath = path + "/image"
    if fileManager.createFile(atPath: imagePath, contents: data) {
      let createdSize = (try? size()) ?? 0
      await cacheSizeCalculator.add(createdSize)
      return URL(fileURLWithPath: imagePath)
    }
    return nil
  }
  
  func remove() async throws {
    let destination = cacheURL.append(path: name)
    let deleteFileSize = (try? size()) ?? 0
    try fileManager.removeItem(at: destination)
    await cacheSizeCalculator.subtract(deleteFileSize)
  }
  
  func size() throws -> Int? {
    return try fileManager.contentsOfDirectory(
      at: cacheURL.append(path: name),
      includingPropertiesForKeys: [.fileSizeKey],
      options: [.skipsHiddenFiles]
    ).reduce(0, { totalSize, file in
      guard let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return totalSize }
      return totalSize + fileSize
    })
  }
  
  func createDate() async throws -> Date? {
    let destination = cacheURL.append(path: name)
    return try fileManager.attributesOfItem(atPath: destination.toPath())[.creationDate] as? Date
  }
  
  func setAttributes(_ attributes: [FileAttributeKey: Any]) throws {
    let destination = cacheURL.append(path: name)
    try fileManager.setAttributes(attributes, ofItemAtPath: destination.toPath())
  }
}

private extension CacheItem {
  func createETagAndModifiedFile(path: String, eTag: String?, modified: String?) {
    if let eTag,
       let eTagData = eTag.data(using: .utf8) {
      fileManager.createFile(atPath: path + "/eTag.txt", contents: eTagData)
    }
    if let modified,
       let modifiedData = modified.data(using: .utf8) {
      fileManager.createFile(atPath: path + "/modified.txt", contents: modifiedData)
    }
  }
  
  func createCacheItemDirectory(destination: URL) -> Bool {
    if !fileManager.fileExists(atPath: cacheURL.toPath()) {
      try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    guard !fileManager.fileExists(atPath: destination.path) else { return false }
    do {
      try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
      return true
    } catch {
      return false
    }
  }
}
