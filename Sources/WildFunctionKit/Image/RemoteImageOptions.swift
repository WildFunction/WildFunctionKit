import UIKit

/// Options for loading a remote image.
public struct RemoteImageOptions: Sendable {
    /// Image shown when loading fails. `nil` keeps the placeholder.
    public var failureImage: UIImage?

    /// Fade-in duration in seconds. `<= 0` disables the transition.
    public var fadeDuration: TimeInterval

    /// Whether to downsample to the view's size while decoding. Skipped when the view has no size yet.
    public var downsamplesToViewSize: Bool

    /// Creates loading options.
    public init(
        failureImage: UIImage? = nil,
        fadeDuration: TimeInterval = RemoteImageOptions.defaultFadeDuration,
        downsamplesToViewSize: Bool = true
    ) {
        self.failureImage = failureImage
        self.fadeDuration = fadeDuration
        self.downsamplesToViewSize = downsamplesToViewSize
    }

    /// Default fade-in duration.
    public static let defaultFadeDuration: TimeInterval = 0.2
}

/// Why a remote image failed to load.
public enum RemoteImageError: Error, Equatable, Sendable {
    /// The URL is missing, unparsable, or its scheme is not `https`, `http` or `file`.
    case invalidURL
    /// The load was cancelled manually or superseded by a newer load on the same view.
    case cancelled
    /// Download or decoding failed, with the underlying description.
    case failed(String)
}
