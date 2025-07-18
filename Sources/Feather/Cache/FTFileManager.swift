//
//  FTFileManager.swift
//  Feather
//
//  Created by 이시원 on 2/27/25.
//

import Foundation

actor FTFileManager: Sendable {
  private let cacheDirectory: URL
  private let fileManager: FileManager = .default
  static let shared = FTFileManager()
  private var totalCacheSize: Int?
  
  init() {
    let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    self.cacheDirectory = paths[0].appendingPathComponent("ImageCache")
  }
  
  func getTotalCacheSize() -> Int {
    guard let totalCacheSize else {
      let totalSize = calculateTotalSize()
      totalCacheSize = totalSize
      return totalSize
    }
    return totalCacheSize
  }
  
  func readCache(
    fileName: String
  ) -> (imageURL: URL, eTag: String?, modified: String?)? {
    let destination = cacheDirectory.append(path: fileName)
    guard fileManager.fileExists(atPath: destination.path) else { return nil }
    let imageURL = destination.append(path: "image")
    let eTag = try? String(contentsOf: destination.append(path: "eTag.txt"), encoding: .utf8)
    let modified = try? String(contentsOf: destination.append(path: "modified.txt"), encoding: .utf8)
    return (imageURL, eTag, modified)
  }
  
  @discardableResult
  func create(fileName: String, data: Data?, eTag: String?, modified: String?) -> URL? {
    let destination = cacheDirectory.append(path: fileName)
    guard createCacheItemDirectory(destination: destination) else { return destination.append(path: "image") }
    let totalSize = getTotalCacheSize()
    defer {
      let createFileSize = (try? directorySize(at: destination)) ?? 0
      totalCacheSize = totalSize + createFileSize
    }
    return createCache(
      path: destination.gatPath(),
      data: data,
      eTag: eTag,
      modified: modified
    )
  }
  
  @discardableResult
  func create(fileName: String, tempURL: URL, eTag: String?, modified: String?) -> URL? {
    let destination = cacheDirectory.append(path: fileName)
    guard createCacheItemDirectory(destination: destination) else { return destination.append(path: "image") }
    let totalSize = getTotalCacheSize()
    defer {
      let createFileSize = (try? directorySize(at: destination)) ?? 0
      totalCacheSize = totalSize + createFileSize
    }
    return createCache(
      path: destination.gatPath(),
      tempURL: tempURL,
      eTag: eTag,
      modified: modified
    )
  }
  
  func remove(fileName: String) throws {
    let destination = cacheDirectory.append(path: fileName)
    let deleteFileSize = (try? directorySize(at: destination)) ?? 0
    try fileManager.removeItem(at: destination)
    let totalSize = getTotalCacheSize()
    totalCacheSize = totalSize - deleteFileSize
  }
  
  func removeAll() throws {
    if fileManager.fileExists(atPath: cacheDirectory.gatPath()) {
      try fileManager.removeItem(at: cacheDirectory)
    }
    totalCacheSize = 0
  }
  
  func getFileCreateDate(fileName: String) async throws -> Date? {
    let destination = cacheDirectory.append(path: fileName)
    return try fileManager.attributesOfItem(atPath: destination.gatPath())[.creationDate] as? Date
  }
  
  func setAttributes(_ attributes: [FileAttributeKey: Any], fileName: String) throws {
    let destination = cacheDirectory.append(path: fileName)
    try fileManager.setAttributes(attributes, ofItemAtPath: destination.gatPath())
  }
  
  func contentsOfDirectory(includingPropertiesForKeys: [URLResourceKey]?) -> [URL]? {
    return try? fileManager.contentsOfDirectory(
      at: cacheDirectory,
      includingPropertiesForKeys: includingPropertiesForKeys,
      options: []
    )
  }
  
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
}

extension FTFileManager {
  private func calculateTotalSize() -> Int {
    guard let files = contentsOfDirectory(includingPropertiesForKeys: nil) else { return 0 }
    return files.reduce(0) { totalSize, file in
      let fileSize = (try? self.directorySize(at: file)) ?? 0
      return totalSize + fileSize
    }
  }
  
  private func createCache(path: String, data: Data?, eTag: String?, modified: String?) -> URL? {
    createETagAndModifiedFile(path: path, eTag: eTag, modified: modified)
    if fileManager.createFile(atPath: path + "/image", contents: data) {
      return URL(fileURLWithPath: path + "/image")
    }
    return nil
  }
  
  private func createCache(path: String, tempURL: URL, eTag: String?, modified: String?) -> URL? {
    createETagAndModifiedFile(path: path, eTag: eTag, modified: modified)
    let imageFileURL = URL(fileURLWithPath: path + "/image")
    do {
      try fileManager.moveItem(at: tempURL, to: imageFileURL)
      return imageFileURL
    } catch {
      return nil
    }
  }
  
  private func createCacheItemDirectory(destination: URL) -> Bool {
    if !fileManager.fileExists(atPath: cacheDirectory.gatPath()) {
      try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    guard !fileManager.fileExists(atPath: destination.path) else { return false }
    do {
      try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
      return true
    } catch {
      return false
    }
  }
  
  private func createETagAndModifiedFile(path: String, eTag: String?, modified: String?) {
    if let eTag,
       let eTagData = eTag.data(using: .utf8) {
      fileManager.createFile(atPath: path + "/eTag.txt", contents: eTagData)
    }
    if let modified,
       let modifiedData = modified.data(using: .utf8) {
      fileManager.createFile(atPath: path + "/modified.txt", contents: modifiedData)
    }
  }
}

private extension URL {
  func append(path: String) -> URL {
    if #available(iOS 16.0, *) {
      return self.appending(path: path)
    } else {
      return self.appendingPathComponent(path)
    }
  }
  
  func gatPath() -> String {
    if #available(iOS 16.0, *) {
      return self.path()
    } else {
      return self.path
    }
  }
}
