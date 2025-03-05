//
//  FTDiskCacheTests.swift
//  Feather
//
//  Created by 이시원 on 3/5/25.
//

import XCTest
@testable import Feather

final class FTDiskCacheTests: XCTestCase {
  var sut: FTDiskCache!
  
  override func setUp() {
    sut = FTDiskCache()
  }
  
  override func tearDown() async throws {
    try await sut.clean()
    sut = nil
  }
  
  func test_save() async {
    // Arrange
    let requestURL = URL(string: "https://example.com/image.jpg")!
    let data = Data()
    // Act
    let isScucess = await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: nil,
      modified: nil
    )
    // Assert
    XCTAssertTrue(isScucess)
  }
  
  func test_save_호출_시_이미_캐시가_존재할_경우_false() async {
    // Arrange
    let requestURL = URL(string: "https://example.com/image.jpg")!
    let data = Data()
    await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: nil,
      modified: nil
    )
    // Act
    let isScucess = await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: nil,
      modified: nil
    )
    // Assert
    XCTAssertFalse(isScucess)
  }
  
  func test_read() async {
    // Arrange
    let requestURL = URL(string: "https://example.com/image.jpg")!
    let data = UIImage(systemName: "swift")!.pngData()!
    await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: nil,
      modified: nil
    )
    // Act
    let output = await sut.read(requestURL: requestURL)
    // Assert
    XCTAssertNotNil(output)
    XCTAssertTrue(output!.isHit)
    XCTAssertEqual(output!.cacheInfo.imageData, data)
  }
  
  func test_read_호출_시_timeOut된_경우_isHit_false_및_해당_캐시_제거됨() async {
    // Arrange
    sut = FTDiskCache(ttl: 0)
    let requestURL = URL(string: "https://example.com/image.jpg")!
    let data = UIImage(systemName: "swift")!.pngData()!
    let eTag = "eTag"
    await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: eTag,
      modified: nil
    )
    // Act
    let output = await sut.read(requestURL: requestURL)
    let retry = await sut.read(requestURL: requestURL)
    // Assert
    XCTAssertNotNil(output)
    XCTAssertFalse(output!.isHit)
    XCTAssertEqual(output!.cacheInfo.eTag, eTag)
    XCTAssertNil(retry)
  }
  
  func test_read_호출_시_캐시가_존재하지_않을_경우_nil() async {
    // Arrange
    let requestURL = URL(string: "https://example.com/image.jpg")!
    // Act
    let output = await sut.read(requestURL: requestURL)
    // Assert
    XCTAssertNil(output)
  }
}
