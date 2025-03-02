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
  
  func fileExists(fileName: String) -> Bool {
    let destination = path(fileName: fileName)
    return fileManager.fileExists(atPath: destination.path)
  }
  
  @discardableResult
  func create(fileName: String, data: Data?, eTag: String?, modified: String?) -> Bool {
    if !fileManager.fileExists(atPath: cacheDirectory.path()) {
      try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    let directoryURL = cacheDirectory.appending(path: fileName)
    try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    let destination = path(fileName: fileName)
    if let eTag,
       let eTagData = eTag.data(using: .utf8) {
      fileManager.createFile(atPath: destination.path() + "/eTag.txt", contents: eTagData)
    }
    if let modified,
       let modifiedData = modified.data(using: .utf8) {
      fileManager.createFile(atPath: destination.path() + "/modified.txt", contents: modifiedData)
    }
    defer {
      let createFileSize = (try? directorySize(at: destination)) ?? 0
      let totalSize = getTotalCacheSize()
      totalCacheSize = totalSize + createFileSize
    }
    return fileManager.createFile(atPath: destination.path() + "/image", contents: data)
  }
  
  func remove(fileName: String) throws {
    let destination = path(fileName: fileName)
    let deleteFileSize = (try? directorySize(at: destination)) ?? 0
    try fileManager.removeItem(at: destination)
    let totalSize = getTotalCacheSize()
    totalCacheSize = totalSize - deleteFileSize
  }
  
  func removeAll() throws {
    if fileManager.fileExists(atPath: cacheDirectory.path()) {
      try fileManager.removeItem(at: cacheDirectory)
    }
  }
  
  func getFileCreateDate(fileName: String) async throws -> Date? {
    let destination = path(fileName: fileName)
    return try fileManager.attributesOfItem(atPath: destination.path())[.creationDate] as? Date
  }
  
  func setAttributes(_ attributes: [FileAttributeKey: Any], fileName: String) throws {
    let destination = path(fileName: fileName)
    try fileManager.setAttributes(attributes, ofItemAtPath: destination.path())
  }
  
  func contentsOfDirectory(includingPropertiesForKeys: [URLResourceKey]?) throws -> [URL] {
    return try fileManager.contentsOfDirectory(
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
  
  func path(fileName: String) -> URL {
    return cacheDirectory.appending(path: fileName)
  }
}

extension FTFileManager {
  private func calculateTotalSize() -> Int {
    let files =  try! contentsOfDirectory(includingPropertiesForKeys: nil)
    return files.reduce(0) { totalSize, file in
      let fileSize = (try? self.directorySize(at: file)) ?? 0
      return totalSize + fileSize
    }
  }
}
