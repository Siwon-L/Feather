//
//  FTDownloader.swift
//  Feather
//
//  Created by 이시원 on 2/28/25.
//

import Foundation

final class FTDownloader: Sendable {
  private let diskCache: FTDiskCache
  static let shared = FTDownloader()
  
  init(diskCache: FTDiskCache = .shared) {
    self.diskCache = diskCache
  }
  
  func download(url: URL) async throws -> URL {
    var tempFileURL: URL!
    var eTag: String?
    var modified: String?
    
    if let (cache, isHit) = await diskCache.read(requestURL: url) {
      if isHit {
        return cache.imageURL
      } else {
        tempFileURL = cache.imageURL
        eTag = cache.eTag
        modified = cache.modified
      }
    }
    
    let urlRequest = configureURLRequest(URLRequest(url: url), eTag: eTag, modified: modified)
    
    guard let (fileURL, response) = try? await URLSession.shared.download(for: urlRequest),
          let response = response as? HTTPURLResponse else {
      throw URLError(.unknown)
    }
    switch response.statusCode {
    case 200..<300:
      if let eTag = response.allHeaderFields["ETag"] as? String {
        await diskCache.save(requestURL: url, imageFile: fileURL, eTag: eTag, modified: nil)
        return fileURL
      } else if let lastModified = response.allHeaderFields["Last-Modified"] as? String {
        await diskCache.save(requestURL: url, imageFile: fileURL, eTag: nil, modified: lastModified)
        return fileURL
      }
      return fileURL
    case 304:
      await diskCache.save(requestURL: url, imageFile: tempFileURL, eTag: eTag, modified: modified)
      return tempFileURL
    default: throw URLError(.badServerResponse)
    }
  }
  
  private func configureURLRequest(_ urlRequest: URLRequest, eTag: String?, modified: String?) -> URLRequest {
    var urlRequest = urlRequest
    urlRequest.httpMethod = "GET"
    if let eTag {
      urlRequest.addValue("If-None-Match", forHTTPHeaderField: eTag)
    } else if let modified {
      urlRequest.addValue("If-Modified-Since", forHTTPHeaderField: modified)
    }
    return urlRequest
  }
}
