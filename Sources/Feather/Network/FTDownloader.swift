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
  
  func download(url: URL) async throws -> URL? {
    var tempData: Data!
    var eTag: String?
    var modified: String?
    
    if let (cache, isHit) = await diskCache.read(requestURL: url) {
      if isHit {
        return cache.imageURL
      } else {
        tempData = cache.imageData
        eTag = cache.eTag
        modified = cache.modified
      }
    }
    
    let urlRequest = configureURLRequest(URLRequest(url: url), eTag: eTag, modified: modified)
    
    guard let (tempURL, response) = try? await URLSession.shared.download(for: urlRequest),
          let response = response as? HTTPURLResponse else {
      throw URLError(.unknown)
    }
    switch response.statusCode {
    case 200..<300:
      if let headers = response.allHeaderFields as? [String: Any] {
        let lowercasedHeaders = Dictionary(uniqueKeysWithValues: headers.map { ($0.lowercased(), $1) })
        if let eTag = lowercasedHeaders["etag"] as? String {
          return try await diskCache.save(requestURL: url, tempURL: tempURL, eTag: eTag, modified: nil)
        }  else if let lastModified = lowercasedHeaders["last-modified"] as? String {
          return try await diskCache.save(requestURL: url, tempURL: tempURL, eTag: nil, modified: lastModified)
        }
      }
      return try await diskCache.save(requestURL: url, tempURL: tempURL, eTag: nil, modified: nil)
    case 304:
      return await diskCache.save(requestURL: url, data: tempData, eTag: eTag, modified: modified)
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
