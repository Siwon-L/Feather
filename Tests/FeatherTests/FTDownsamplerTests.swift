//
//  FTDownsamplerTests.swift
//  Feather
//
//  Created by 이시원 on 3/14/25.
//

import XCTest
@testable import Feather

final class FTDownsamplerTests: XCTestCase {
  var sut: FTDownsampler!
  
  override func setUp() {
    sut = FTDownsampler()
  }
  
  override func tearDown() {
    sut = nil
  }
  
  func test_downsample() async {
    // Arrange
    let imageURL = Bundle.module.url(forResource: "dummy_image", withExtension: "png")
    let originalData = UIImage(contentsOfFile: imageURL!.path)!.pngData()!
    // Act
    let cgImage = await sut.downsample(imageURL!, pixelSize: 100)!
    let downsampledData = UIImage(cgImage: cgImage).pngData()!
    // Assert
    XCTAssertTrue(originalData.count > downsampledData.count)
  }
}
