import XCTest
@testable import Feather

final class FTFileManagerTests: XCTestCase {
  var sut: FTFileManager!
  
  override func setUpWithError() throws {
    sut = FTFileManager()
  }
  
  override func tearDownWithError() throws {
    try sut.removeAll()
    sut = nil
  }
  
  func test_create() {
    // Arrange
    let input = Data()
    let fileName = "test"
    // Act
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Assert
    XCTAssertTrue(sut.fileExists(fileName: fileName))
  }
  
  func test_remove() {
    // Arrange
    let input = Data()
    let fileName = "test"
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    let deleteURL = sut.remove(fileName: fileName)
    // Assert
    XCTAssertEqual(deleteURL, sut.path(fileName: fileName))
    XCTAssertFalse(sut.fileExists(fileName: fileName))
  }
  
  func test_remove_fail() {
    // Arrange
    let fileName = "test"
    // Act
    let result = sut.remove(fileName: fileName)
    // Assert
    XCTAssertNil(result)
  }
  
  func test_get_attributes() {
    // Arrange
    let input = Data()
    let fileName = "test"
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      let attributes = try sut.attributesOfItem(fileName: fileName)
      // Assert
      XCTAssertNotNil(attributes[.creationDate] as? Date)
    } catch {
      XCTFail("속성 가져오기 실패")
    }
  }
  
  func test_set_attributes() {
    // Arrange
    let input = Data()
    let fileName = "test"
    let currentDate = Date()
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      try sut.setAttributes(
        [.modificationDate: currentDate],
        fileName: fileName
      )
      let attribute = try sut.attributesOfItem(fileName: fileName)[.modificationDate] as? Date
      // Assert
      XCTAssertEqual(attribute, currentDate)
    } catch {
      XCTFail("속성 업데이트 실패")
    }
  }
  
  func test_read_directory() {
    // Arrange
    let input = Data()
    let fileName = "test"
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    do {
      let url = try sut.contentsOfDirectory(includingPropertiesForKeys: nil).filter { $0.lastPathComponent == fileName }.first!
      
      // Assert
      XCTAssertEqual(url.lastPathComponent, fileName)
    } catch {
      XCTFail("디렉토리 읽기 실패")
    }
  }
  
  func test_get_size() {
    // Arrange
    let input = UIImage(systemName: "swift")!.pngData()!
    let fileName = "test"
    sut.create(fileName: fileName, data: input, eTag: nil, modified: nil)
    // Act
    let path = sut.path(fileName: fileName)
    let size = try! sut.directorySize(at: path)
    // Assert
    XCTAssertEqual(input.count, size)
  }
}
