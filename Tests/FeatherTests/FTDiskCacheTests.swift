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
    let url = await sut.save(
      requestURL: requestURL,
      data: data,
      eTag: nil,
      modified: nil
    )
    // Assert
    XCTAssertNotNil(url)
  }
  
  func test_save_호출_시_이미_캐시가_존재할_경우_이전에_캐싱된_이미지가_반환된다() async {
    // Arrange
    let requestURL = URL(string: "https://example.com/image.jpg")!
    let firstData = UIImage(systemName: "swift")!.pngData()!
    let secondData = Data()
    // Act
    let _ = await sut.save(
      requestURL: requestURL,
      data: firstData,
      eTag: nil,
      modified: nil
    )
    
    let output = await sut.save(
      requestURL: requestURL,
      data: secondData,
      eTag: nil,
      modified: nil
    )
    // Assert
    XCTAssertEqual(firstData.count, try! Data(contentsOf: output!).count)
    XCTAssertNotEqual(secondData.count, try! Data(contentsOf: output!).count)
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
    XCTAssertEqual(try! Data(contentsOf: output!.cacheInfo.imageURL!), data)
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
