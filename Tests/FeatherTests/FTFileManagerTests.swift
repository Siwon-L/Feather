import XCTest
@testable import Feather

final class FTFileManagerTests: XCTestCase {
  var sut: FTFileManager!
  var cacheDirectory: URL!
  
  override func setUpWithError() throws {
    sut = FTFileManager()
    cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ImageCache")
  }
  
  override func tearDown() async throws {
    try await sut.removeAll()
    sut = nil
    cacheDirectory = nil
  }
  
  func test_create() async {
    // Arrange
    let input = Data()
    let fileName = "test"
    // Act
    let url = await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Assert
    XCTAssertNotNil(url)
  }
  
  func test_remove() async {
    // Arrange
    let input = Data()
    let fileName = "test"
    await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      try await sut.remove(fileName: fileName)
      // Assert
      let output = await sut.readCache(fileName: fileName)
      XCTAssertNil(output)
    } catch {
      XCTFail()
    }
  }
  
  func test_remove_fail() async {
    // Arrange
    let fileName = "test"
    // Act
    do {
      try await sut.remove(fileName: fileName)
      // Assert
      XCTFail()
    } catch {
      
    }
  }
  
  func test_get_attributes() async {
    // Arrange
    let input = Data()
    let fileName = "test"
    await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      let createDate = try await sut.getFileCreateDate(fileName: fileName)
      // Assert
      XCTAssertNotNil(createDate)
    } catch {
      XCTFail("속성 가져오기 실패")
    }
  }
  
  func test_set_attributes() async {
    // Arrange
    let input = Data()
    let fileName = "test"
    let currentDate = Date()
    await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      try await sut.setAttributes(
        [.modificationDate: currentDate],
        fileName: fileName
      )
      let modifiedDate = try cacheDirectory.appendingPathComponent(fileName).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate!
      // Assert
      XCTAssertEqual(modifiedDate, currentDate)
    } catch {
      XCTFail("속성 업데이트 실패")
    }
  }
  
  func test_read_directory() async {
    // Arrange
    let input = Data()
    let fileName = "test"
    await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    let url = await sut.contentsOfDirectory(includingPropertiesForKeys: nil)!.filter { $0.lastPathComponent == fileName }.first!
    
    // Assert
    XCTAssertEqual(url.lastPathComponent, fileName)
  }
  
  func test_get_size() async {
    // Arrange
    let input = UIImage(systemName: "swift")!.pngData()!
    let fileName = "test"
    await sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    let path = cacheDirectory.appendingPathComponent(fileName)
    let size = try! await sut.directorySize(at: path)
    // Assert
    XCTAssertEqual(input.count, size)
  }
}
