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
      guard let config else { self.ttl = FTConstant.defaultTimeOut; return }
      self.ttl = config.timeOut
    }
  }
  
  private let fileManager: FTFileManager
  private var ttl: TimeInterval
  
  init(
    fileManager: FTFileManager = FTFileManager.shared,
    ttl: TimeInterval = FTConstant.defaultTimeOut
  ) {
    self.fileManager = fileManager
    self.ttl = ttl
  }
  
  func save(requestURL: URL, data: Data, eTag: String?, modified: String?) async {
    let fileName = sha256(requestURL.absoluteString)
    guard await !fileManager.fileExists(fileName: fileName) else { return }
    await fileManager.create(fileName: fileName, data: data, eTag: eTag, modified: modified)
    if let deleteFiles = await config?.policy?.execute() {
      for deleteFile in deleteFiles {
        await delete(fileName: deleteFile.lastPathComponent)
      }
    }
  }
  
  func read(requestURL: URL) async -> (FTCacheInfo, Bool)? {
    let fileName = sha256(requestURL.absoluteString)
    let readFileURL = await fileManager.path(fileName: fileName)
    guard await fileManager.fileExists(fileName: fileName),
          let imageData = try? Data(contentsOf: readFileURL.appending(path: "image")) else { return nil }
    if await isTimeOut(fileName: fileName) {
      let cache = FTCacheInfo(
        imageData: imageData,
        eTag: try? String(contentsOf: readFileURL.appending(path: "eTag.txt"), encoding: .utf8),
        modified: try? String(contentsOf: readFileURL.appending(path: "modified.txt"), encoding: .utf8)
      )
      await delete(fileName: fileName)
      return (cache, false)
    }
    await config?.policy?.updateAccessTime(fileName: fileName)
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
  
  private func delete(fileName: String) async {
    try? await fileManager.remove(fileName: fileName)
  }
  
  private func isTimeOut(fileName: String) async -> Bool {
    if let creationDate = try? await fileManager.getFileCreateDate(fileName: fileName) {
      if ttl < Date().timeIntervalSince(creationDate) {
        return true
      }
    }
    return false
  }
}
