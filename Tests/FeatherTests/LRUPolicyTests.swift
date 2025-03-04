//
//  LRUPolicyTests.swift
//  Feather
//
//  Created by 이시원 on 3/4/25.
//

import XCTest
@testable import Feather

final class LRUPolicyTests: XCTestCase {
  var fileManager: FTFileManager!
  var sut: LRUPolicy!
  
  override func setUpWithError() throws {
    fileManager = FTFileManager.shared
    sut = LRUPolicy(maxSize: 1024 * 6)
  }
  
  override func tearDown() async throws {
    try await fileManager.removeAll()
    fileManager = nil
    sut = nil
  }
  
  func test_update_access_time() async {
    // Arrange
    let fileName = "test"
    let updateDate = Date().addingTimeInterval(60 * 60)
    await fileManager.create(fileName: fileName, data: Data(), eTag: nil, modified: nil)
    // Act
    await sut.updateAccessTime(fileName: fileName, date: updateDate)
    // Assert
    do {
      let modifiedDate = try await fileManager.path(fileName: fileName).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
      XCTAssertEqual(modifiedDate, updateDate)
    } catch {
      XCTFail()
    }
  }
  
  func test_execute_호출_시_가장_오랫동안_접근하지_않은_file_path_반환() async {
    // Arrange
    let fileName1 = "test1"
    let imageData1 = UIImage(systemName: "swift")?.pngData()!
    await fileManager.create(fileName: fileName1, data: imageData1, eTag: nil, modified: nil)
    
    let fileName2 = "test2"
    let imageData2 = UIImage(systemName: "swift")?.pngData()!
    await fileManager.create(fileName: fileName2, data: imageData2, eTag: nil, modified: nil)
    
    let fileName3 = "test3"
    let imageData3 = UIImage(systemName: "swift")?.pngData()!
    await fileManager.create(fileName: fileName3, data: imageData3, eTag: nil, modified: nil)
    await sut.updateAccessTime(fileName: fileName1, date: Date.now)
    // Act
    let output = await sut.execute()
    // Assert
    XCTAssertEqual(output.map(\.lastPathComponent), [fileName2, fileName3])
  }
}
