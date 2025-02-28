import UIKit

open class FTImageView: UIImageView {
  private let imageURL: URL
  private let imageDownloader: FTDownloader = .shared
  
  // 다운로드 작업을 보관하기 위한 프로퍼티 추가
  private var downloadTask: Task<Void, any Error>? = nil
  
  public init(_ imageURL: URL) {
    self.imageURL = imageURL
    super.init(frame: .zero)
  }
  
  @available(*, unavailable)
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override open func layoutSubviews() {
    super.layoutSubviews()
    // 기존 작업이 있으면 취소
    downloadTask?.cancel()
    
    // 새로운 다운로드 작업 시작
    downloadTask = Task { [weak self] in
      guard let self = self else { return }
      // 다운로드 작업이 취소되었는지 중간에 확인할 수 있음
      let downloadedURL = try await imageDownloader.download(url: imageURL)
      if Task.isCancelled { return }
      let image = UIImage(contentsOfFile: downloadedURL.path())
      await MainActor.run {
        self.image = image
      }
    }
  }
  
  // 뷰가 윈도우에서 제거될 때 다운로드 작업 취소
  override open func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      downloadTask?.cancel()
    }
  }
  
  deinit {
    // 뷰가 deinit될 때도 다운로드 작업 취소
    downloadTask?.cancel()
  }
}
