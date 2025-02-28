//
//  FTDiskCache.swift
//  Feather
//
//  Created by 이시원 on 2/27/25.
//

import CryptoKit
import Foundation

public final class FTDiskCache: @unchecked Sendable {
  public static let shared = FTDiskCache()
  public var config: FTDiskCacheConfig? = nil {
    didSet {
      guard let config else { return }
      self.ttl = config.timeOut
    }
  }
  
  private let fileManager: FTFileManager
  private var ttl: TimeInterval
  
  init(
    fileManager: FTFileManager = FTFileManager(),
    ttl: TimeInterval = 60 * 60 * 24
  ) {
    self.fileManager = fileManager
    self.ttl = ttl
  }
  
  func save(requestURL: URL, data: Data, eTag: String?, modified: String?) {
    let fileName = sha256(requestURL.absoluteString)
    guard !fileManager.fileExists(fileName: fileName) else { return }
    //trimLRUCache()
    fileManager.create(fileName: fileName, data: data, eTag: eTag, modified: modified)
    //updateAccessTime(fileName: fileName)
  }
  
  func read(requestURL: URL) -> (FTCacheInfo, Bool)? {
    let fileName = sha256(requestURL.absoluteString)
    let readFileURL = fileManager.path(fileName: fileName)
    guard fileManager.fileExists(fileName: fileName),
          let imageData = try? Data(contentsOf: readFileURL.appending(path: "image")) else { return nil }
    if isTimeOut(fileName: fileName) {
      let cache = FTCacheInfo(
        imageData: imageData,
        eTag: try? String(contentsOf: readFileURL.appending(path: "eTag.txt"), encoding: .utf8),
        modified: try? String(contentsOf: readFileURL.appending(path: "modified.txt"), encoding: .utf8)
      )
      delete(fileName: fileName)
      return (cache, false)
    }
    //updateAccessTime(fileName: fileName)
    let cache = FTCacheInfo(
      imageData: imageData,
      eTag: nil,
      modified: nil
    )
    return (cache, true)
  }
}

extension FTDiskCache {
  private func sha256(_ string: String) -> String {
      let data = Data(string.utf8)
      let hash = SHA256.hash(data: data)
      return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
  
  private func delete(fileName: String) {
    try? fileManager.remove(fileName: fileName)
  }
  
  private func isTimeOut(fileName: String) -> Bool {
    if let attributes = try? fileManager.attributesOfItem(fileName: fileName),
       let creationDate = attributes[.creationDate] as? Date {
      if ttl < Date().timeIntervalSince(creationDate) {
        return true
      }
    }
    return false
  }
}
