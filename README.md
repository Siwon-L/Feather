# Feather

<div align="center">   
Feather offers lightweight yet powerful image downloading and caching capabilities.
</div>


## Features
- Asynchronous image downloading and caching based on Swift Concurrency
- Efficient caching data handling using `ETag` and `Last-Modified`
- Cancels previous tasks when a new image URL is set
- Configurable cache expiration time
- Set a maximum cache size and manage data efficiently using LRU (Least Recently Used)
- Prevent data races using `Actor`
- Image Downsampling

### Image Download & Caching

```swift
import Feather

let imageView = FTImageView()
imageView.setImageURL(URL(string: "https://example.com/sample.png")!)
```
`FTImageView` is a subclass of `UIImageView`. You can download and cache images via URL using the `setImageURL(_ url:)` method of `FTImageView`. If the same URL is requested again, the cached image will be loaded instead.

### Cache Configuration
```swift
import Feather

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FTDiskCache.shared.config = FTDiskCacheConfig(timeOut: 7 * 24 * 60 * 60, policy: .LRU(maxSize: 1024 * 1024 * 1000))
    return true
  }
}
```
You can configure the cache expiration time using FTDiskCacheConfig.

Expired cache images are also refreshed more efficiently by leveraging the `ETag` and `Last-Modified` HTTP headers.

Furthermore, you can set the maximum cache size and choose the caching policy that fits your needs. Feather efficiently manages cached data using the LRU (Least Recently Used) algorithm.

## Installation

### Swift Package Manager
1. File > Swift Packages > Add Package Dependency
2. Add `https://github.com/Siwon-L/Feather.git`
3. Select "Up to Next Major" with "1.1.0"

## License
Feather is released under the MIT license. See LICENSE for details.
