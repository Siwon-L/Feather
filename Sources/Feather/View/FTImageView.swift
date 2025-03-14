import UIKit

open class FTImageView: UIImageView {
  private let imageDownloader: FTDownloader = .shared
  private var downloadTask: Task<Void, any Error>? = nil
  
  deinit {
    downloadTask?.cancel()
    downloadTask = nil
  }
  
  public func setImageURL(_ url: URL) {
    downloadTask?.cancel()
    downloadTask = nil
    image = nil
    
    // 새로운 다운로드 작업 시작
    downloadTask = Task.detached { [weak self] in
      guard let self = self else { return }
      // 다운로드 작업이 취소되었는지 중간에 확인할 수 있음
      guard let downloadURL = try? await imageDownloader.download(url: url) else { return }
      if Task.isCancelled { return }
      guard let image = UIImage(contentsOfFile: downloadURL.path) else { return }
      await MainActor.run {
        self.image = image
      }
    }
  }
}
