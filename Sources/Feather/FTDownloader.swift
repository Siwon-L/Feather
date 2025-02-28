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
  
  func download(url: URL) async throws -> Data {
    var tempData: Data!
    var eTag: String?
    var modified: String?
    
    if let (cache, isHit) = diskCache.read(requestURL: url) {
      if isHit {
        return cache.imageData
      } else {
        tempData = cache.imageData
        eTag = cache.eTag
        modified = cache.modified
      }
    }
    
    let urlRequest = configureURLRequest(URLRequest(url: url), eTag: eTag, modified: modified)
    
    guard let (data, response) = try? await URLSession.shared.data(for: urlRequest),
          let response = response as? HTTPURLResponse else {
      throw URLError(.unknown)
    }
    switch response.statusCode {
    case 200..<300:
      guard let headers = response.allHeaderFields as? [String: Any] else { return data }
      let lowercasedHeaders = Dictionary(uniqueKeysWithValues: headers.map { ($0.lowercased(), $1) })
      if let eTag = lowercasedHeaders["etag"] as? String {
        diskCache.save(requestURL: url, data: data, eTag: eTag, modified: nil)
        return data
      }  else if let lastModified = lowercasedHeaders["last-modified"] as? String {
        diskCache.save(requestURL: url, data: data, eTag: nil, modified: lastModified)
        return data
      }
      return data
    case 304:
      await diskCache.save(requestURL: url, data: tempData, eTag: eTag, modified: modified)
      return tempData
    default: throw URLError(.badServerResponse)
    }
  }
  
  private func configureURLRequest(_ urlRequest: URLRequest, eTag: String?, modified: String?) -> URLRequest {
    var urlRequest = urlRequest
    urlRequest.httpMethod = "GET"
    if let eTag {
      urlRequest.addValue(eTag, forHTTPHeaderField: "If-None-Match")
    } else if let modified {
      urlRequest.addValue(modified, forHTTPHeaderField: "If-Modified-Since")
    }
    return urlRequest
  }
}
