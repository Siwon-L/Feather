//
//  FTFileManager.swift
//  Feather
//
//  Created by 이시원 on 2/27/25.
//

import Foundation

final class FTFileManager: @unchecked Sendable {
  private let cacheDirectory: URL
  private let fileManager: FileManager = .default
  static let shared = FTFileManager()
  
  init() {
    let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    self.cacheDirectory = paths[0].appendingPathComponent("ImageCache")
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
    
    return fileManager.createFile(atPath: destination.path() + "/image", contents: data)
  }
  
  func remove(fileName: String) -> URL? {
    let destination = path(fileName: fileName)
    do {
      try fileManager.removeItem(at: destination)
      return destination
    } catch {
      return nil
    }
  }
  
  func removeAll() throws {
    if fileManager.fileExists(atPath: cacheDirectory.path()) {
      try fileManager.removeItem(at: cacheDirectory)
    }
  }
  
  func attributesOfItem(fileName: String) throws -> [FileAttributeKey: Any] {
    let destination = path(fileName: fileName)
    return try fileManager.attributesOfItem(atPath: destination.path())
  }
  
  func setAttributes(_ attributes: [FileAttributeKey: Any], fileName: String) throws {
    let destination = path(fileName: fileName)
    try fileManager.setAttributes(attributes, ofItemAtPath: destination.path())
  }
  
  func contentsOfDirectory(includingPropertiesForKeys: [URLResourceKey]?) throws -> [URL] {
    return try fileManager.contentsOfDirectory(
      at: cacheDirectory,
      includingPropertiesForKeys: includingPropertiesForKeys,
      options: [.skipsHiddenFiles]
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
