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
    guard let files = await fileManager.contentsOfDirectory(
      includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
    ) else {
      return []
    }
    let totalSize = await fileManager.getTotalCacheSize()
    guard totalSize >= maxSize else { return [] }
    return await deleteFilesExceedingMaxSize(files)
  }
  
  func updateAccessTime(fileName: String, date: Date) async {
    try? await fileManager.setAttributes([.modificationDate: date], fileName: fileName)
  }
}

extension LRUPolicy {
  private func deleteFilesExceedingMaxSize(_ files: [URL]) async -> [URL] {
    var deletFiles: [URL] = []
    var totalSize = await fileManager.getTotalCacheSize()
    let files = files
      .sorted {
        guard let firstFile = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate),
              let secondFile = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) else { return false }
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
