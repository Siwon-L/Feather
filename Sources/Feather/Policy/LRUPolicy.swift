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
  
  func execute(deleteHandler: (String) -> Void) {
    guard let files = try? fileManager.contentsOfDirectory(
      includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
    ) else { return }
    
    let totalFileSize = calculateTotalSize(files)
    guard totalFileSize >= maxSize else { return }
    deleteFilesExceedingMaxSize(files, totalSize: totalFileSize, deleteHandler: deleteHandler)
  }
  
  func updateAccessTime(fileName: String) {
    try? fileManager.setAttributes([.modificationDate: Date.now], fileName: fileName)
  }
}

extension LRUPolicy {
  private func calculateTotalSize(_ files: [URL]) -> Int {
    return files.reduce(0) { totalSize, file in
      let fileSize = (try? fileManager.directorySize(at: file)) ?? 0
      return totalSize + fileSize
    }
  }
  
  private func deleteFilesExceedingMaxSize(_ files: [URL], totalSize: Int, deleteHandler: (String) -> Void) {
    var totalSize = totalSize
    files
      .sorted {
        let firstFile = (try? $0.resourceValues(
          forKeys: [.contentModificationDateKey]).contentModificationDate
        ) ?? .distantPast
        
        let secondFile = (try? $1.resourceValues(
          forKeys: [.contentModificationDateKey]).contentModificationDate
        ) ?? .distantPast
        
        return firstFile < secondFile
      }
      .forEach { file in
        guard totalSize >= maxSize else { return }
        let deletedfileSize = (try? fileManager.directorySize(at: file)) ?? 0
        deleteHandler(file.lastPathComponent)
        totalSize -= deletedfileSize
      }
  }
}
