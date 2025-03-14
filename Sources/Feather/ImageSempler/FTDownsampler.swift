//
//  FTDownsampler.swift
//  Feather
//
//  Created by 이시원 on 3/14/25.
//

import Foundation
import ImageIO

struct FTDownsampler {
  func downsample(_ imageURL: URL, pixelSize: CGFloat) async -> CGImage? {
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else { return nil }
    let downsampleOptions: [NSString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: pixelSize
    ]
    return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
  }
}
