import Kingfisher
import UIKit

/// Completion for image loading, called on the main actor.
public typealias RemoteImageCompletion = @MainActor (Result<UIImage, RemoteImageError>) -> Void

extension UIImageView {
    /// Loads and displays a remote image with memory and disk caching.
    ///
    /// Calling again on the same view cancels the previous load, so it is safe in reusable cells.
    ///
    /// ```swift
    /// imageView.wf_setImage(with: item.coverURL, placeholder: UIImage(named: "cover_placeholder"))
    /// ```
    ///
    /// - Parameters:
    ///   - url: Image URL. `nil` or a disallowed scheme shows the placeholder and fails with `invalidURL`.
    ///   - placeholder: Shown while loading.
    ///   - options: Loading options.
    ///   - completion: Called on the main actor when loading ends.
    public func wf_setImage(
        with url: URL?,
        placeholder: UIImage? = nil,
        options: RemoteImageOptions = RemoteImageOptions(),
        completion: RemoteImageCompletion? = nil
    ) {
        guard let url, RemoteImageLoader.isAllowed(url) else {
            wf_cancelImageLoad()
            image = placeholder
            completion?(.failure(.invalidURL))
            return
        }

        kf.setImage(
            with: RemoteImageLoader.source(for: url),
            placeholder: placeholder,
            options: RemoteImageLoader.options(for: self, options: options)
        ) { result in
            completion?(RemoteImageLoader.map(result))
        }
    }

    /// Loads an image from a URL string. Blank or unparsable strings fail with `invalidURL`.
    public func wf_setImage(
        with urlString: String?,
        placeholder: UIImage? = nil,
        options: RemoteImageOptions = RemoteImageOptions(),
        completion: RemoteImageCompletion? = nil
    ) {
        wf_setImage(with: urlString?.wf_url, placeholder: placeholder, options: options, completion: completion)
    }

    /// Cancels the in-flight load on this view, if any.
    public func wf_cancelImageLoad() {
        kf.cancelDownloadTask()
    }
}

/// Adapter over the image library. Internal; no Kingfisher types leak into the public API.
@MainActor
enum RemoteImageLoader {
    private static let allowedSchemes: Set<String> = ["https", "http", "file"]

    static func isAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return allowedSchemes.contains(scheme)
    }

    /// Local files are read from disk; everything else goes over the network.
    static func source(for url: URL) -> Source {
        url.isFileURL ? .provider(LocalFileImageDataProvider(fileURL: url)) : .network(url)
    }

    static func options(for imageView: UIImageView, options: RemoteImageOptions) -> KingfisherOptionsInfo {
        var info: KingfisherOptionsInfo = []
        if options.fadeDuration > 0 {
            info.append(.transition(.fade(options.fadeDuration)))
        }
        if let failureImage = options.failureImage {
            info.append(.onFailureImage(failureImage))
        }
        if let size = downsampleSize(for: imageView, options: options) {
            info.append(.processor(DownsamplingImageProcessor(size: size)))
            info.append(.scaleFactor(imageView.traitCollection.displayScale))
        }
        return info
    }

    /// Target size in points, or `nil` when disabled or the view has no size yet.
    static func downsampleSize(for imageView: UIImageView, options: RemoteImageOptions) -> CGSize? {
        guard options.downsamplesToViewSize else { return nil }
        let size = imageView.bounds.size
        guard size.width > 0, size.height > 0, imageView.traitCollection.displayScale > 0 else { return nil }
        return size
    }

    static func map(_ result: Result<RetrieveImageResult, KingfisherError>) -> Result<UIImage, RemoteImageError> {
        switch result {
        case .success(let value):
            return .success(value.image)
        case .failure(let error):
            // A manual cancel and being superseded by a newer load both count as cancelled.
            let isCancelled = error.isTaskCancelled || error.isNotCurrentTask
            return .failure(isCancelled ? .cancelled : .failed(error.localizedDescription))
        }
    }
}

/// Image cache management.
public enum RemoteImageCache {
    /// Clears the memory cache.
    public static func clearMemory() {
        ImageCache.default.clearMemoryCache()
    }

    /// Clears the disk cache, then calls `completion` on the main actor.
    public static func clearDisk(completion: (@MainActor @Sendable () -> Void)? = nil) {
        ImageCache.default.clearDiskCache {
            guard let completion else { return }
            Task { @MainActor in completion() }
        }
    }
}
