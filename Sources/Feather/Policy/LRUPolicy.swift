//
//  LRUPolicy.swift
//  Feather
//
//  Created by 이시원 on 2/27/25.
//

import Foundation

struct LRUPolicy: FTPolicy {
  private let maxSize: UInt64
  private let fileManager: FTFileManager
  
  init(maxSize: UInt64, fileManager: FTFileManager = FTFileManager.shared) {
    self.maxSize = maxSize
    self.fileManager = fileManager
  }
  
  func execute() async -> [URL] {
    guard let files = try? await fileManager.contentsOfDirectory(
      includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
    ) else { return [] }
    
    guard await fileManager.getTotalCacheSize() >= maxSize else { return [] }
    return await deleteFilesExceedingMaxSize(files)
  }
  
  func updateAccessTime(fileName: String) async {
    try? await fileManager.setAttributes([.modificationDate: Date.now], fileName: fileName)
  }
}

extension LRUPolicy {
  private func deleteFilesExceedingMaxSize(_ files: [URL]) async -> [URL] {
    var deletFiles: [URL] = []
    var totalSize = await fileManager.getTotalCacheSize()
    let files = files
      .sorted {
        let firstFile = (try? $0.resourceValues(
          forKeys: [.contentModificationDateKey]).contentModificationDate
        ) ?? .distantPast
        
        let secondFile = (try? $1.resourceValues(
          forKeys: [.contentModificationDateKey]).contentModificationDate
        ) ?? .distantPast
        
        return firstFile < secondFile
      }
    for file in files {
      guard totalSize >= maxSize else { break }
      let deletedfileSize = (try? await fileManager.directorySize(at: file)) ?? 0
      totalSize -= deletedfileSize
      deletFiles.append(file)
    }
    return deletFiles
  }
}
