import UIKit

open class FTImageView: UIImageView {
  private let imageDownloader: FTDownloader = .shared
  private var downloadTask: Task<Void, any Error>? = nil
  private let downsampler = FTDownsampler()
  private let placeholder: UIView
  private let indicator: UIActivityIndicatorView?
  
  public init(placeholder: UIView? = nil, indicator: UIActivityIndicatorView? = .init(style: .medium)) {
    let placeholder = placeholder ?? {
      let view = UIView()
      view.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = .systemGray6
      return view
    }()
    self.placeholder = placeholder
    self.indicator = indicator
    super.init(frame: .zero)
    setPlaceholder(placeholder)
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
  }
  
  deinit {
    downloadTask?.cancel()
    downloadTask = nil
  }
  
  private func setPlaceholder(_ view: UIView) {
    self.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: self.topAnchor),
      view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      view.leadingAnchor.constraint(equalTo: self.leadingAnchor)
    ])
    guard let indicator else { return }
    view.addSubview(indicator)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
    indicator.startAnimating()
  }
  
  public func setImageURL(_ url: URL, isDownsampling: Bool = true) {
    downloadTask?.cancel()
    downloadTask = nil
    image = nil
    placeholder.isHidden = false
    indicator?.startAnimating()

    downloadTask = Task { [weak self] in
      guard let self = self,
            let downloadURL = try? await imageDownloader.download(url: url) else { return }
      if Task.isCancelled == true { return }
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
      if isDownsampling, let cgImage = await downsampler.downsample(
        downloadURL,
        pixelSize: pixeSize * UIScreen.main.scale
      ) {
        image = UIImage(cgImage: cgImage)
      } else {
        image = UIImage(contentsOfFile: downloadURL.path)
      }
      self.image = image
      self.placeholder.isHidden = true
      indicator?.stopAnimating()
    }
  }
}
