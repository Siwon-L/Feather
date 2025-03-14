import UIKit

open class FTImageView: UIImageView {
  private let imageDownloader: FTDownloader = .shared
  private var downloadTask: Task<Void, any Error>? = nil
  private let downsampler = FTDownsampler()
  
  deinit {
    downloadTask?.cancel()
    downloadTask = nil
  }
  
  public func setImageURL(_ url: URL, isDownsampling: Bool = true) {
    downloadTask?.cancel()
    downloadTask = nil
    image = nil
    
    downloadTask = Task { [weak self] in
      guard let self = self,
            let downloadURL = try? await imageDownloader.download(url: url) else { return }
      if downloadTask?.isCancelled == true { return }
      let image: UIImage?
      let pixeSize: CGFloat
      switch contentMode {
      case .scaleAspectFill:
        pixeSize = max(frame.width, frame.height)
      case .top, .bottom, .topLeft, .topRight, .bottomLeft, .bottomRight:
        pixeSize = frame.width
      case .left, .right:
        pixeSize = frame.height
      default:
        pixeSize = min(frame.width, frame.height)
      }
      if isDownsampling, let cgImage = await downsampler.downsample(downloadURL, pixelSize: pixeSize) {
        image = UIImage(cgImage: cgImage)
      } else {
        image = UIImage(contentsOfFile: downloadURL.path)
      }
      self.image = image
    }
  }
}
