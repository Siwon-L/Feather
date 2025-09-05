//
//  FTImageModifier.swift
//  Feather
//
//  Created by 이시원 on 8/26/25.
//

import SwiftUI


public struct FTImage: View {
  public init() {}
  public var body: some View {}
}

public struct FTImageModifier: ViewModifier {
  private let imageDownloader: FTDownloader = .shared
  private let downsampler = FTDownsampler()
  private let url: URL
  private let isDownsampling: Bool
  private let placeholder: () -> AnyView
  
  @State private var downloadTask: Task<Void, any Error>? = nil
  @State private var uiimage: UIImage? = nil
  
  public init(url: URL, isDownsampling: Bool, @ViewBuilder placeholder: @escaping () -> some View) {
    self.url = url
    self.isDownsampling = isDownsampling
    self.placeholder = { AnyView(placeholder()) }
  }
  
  public func body(content: Content) -> some View {
    GeometryReader { reader in
      if let uiimage {
        Image(uiImage: uiimage)
          .resizable()
          .onDisappear { cancel() }
      } else {
        placeholder()
          .onAppear { start(reader.size) }
      }
    }
  }
  
  
  private func start(_ size: CGSize) {
    if uiimage != nil { return }
    cancel()
    
    downloadTask = Task {
      guard let downloadURL = try? await imageDownloader.download(url: url) else { return }
      if Task.isCancelled { return }
      let pixelSize = max(size.width, size.height)
      if isDownsampling, let cgImage = await downsampler.downsample(
        downloadURL,
        pixelSize: pixelSize * UIScreen.main.scale
      ) {
        if Task.isCancelled { return }
        uiimage = UIImage(cgImage: cgImage)
      } else {
        uiimage = UIImage(contentsOfFile: downloadURL.path)
      }
    }
  }

  private func cancel() {
    downloadTask?.cancel()
    downloadTask = nil
  }
}

public extension View where Self == FTImage {
  func setImageURL(
  _ url: URL,
  isDownsampling: Bool = true,
  placeholder: @escaping () -> some View = { EmptyView() }
  ) -> some View {
    modifier(FTImageModifier(url: url, isDownsampling: isDownsampling, placeholder: placeholder))
  }
}
