import Foundation
import Kingfisher
import Testing
import UIKit
@testable import WildFunctionKit

@MainActor
private final class ResultBox {
    var result: Result<UIImage, RemoteImageError>?
}

@MainActor
/// Generous timeout: the first load on a cold CI simulator can take a while. Returns as soon as the condition holds.
private func waitUntil(timeout: Duration = .seconds(60), _ condition: @MainActor () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return true
}

/// Drives the real loading pipeline with local file URLs; no network needed.
@MainActor
@Suite("UIImageView+WF", .serialized)
struct UIImageViewWFTests {
    private let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    private let placeholder = Self.makeImage(side: 2)
    private let box = ResultBox()

    private static func makeImage(side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    /// Writes a fresh file each time so earlier tests' cache entries are never hit.
    private static func writeImageFile(side: CGFloat) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wf-\(UUID().uuidString).png")
        try #require(makeImage(side: side).pngData()).write(to: url)
        return url
    }

    private func load(_ url: URL?, options: RemoteImageOptions = RemoteImageOptions(fadeDuration: 0)) async {
        imageView.wf_setImage(with: url, placeholder: placeholder, options: options) { [box] in box.result = $0 }
        #expect(await waitUntil { box.result != nil })
    }

    @Test("A successful load shows the image and reports success")
    func loadsImage() async throws {
        let url = try Self.writeImageFile(side: 8)
        imageView.wf_setImage(with: url, placeholder: placeholder, options: RemoteImageOptions(fadeDuration: 0)) { [box] in
            box.result = $0
        }
        // The placeholder is shown until loading finishes.
        #expect(imageView.image === placeholder)
        #expect(await waitUntil { box.result != nil })

        let image = try #require(try box.result?.get())
        #expect(imageView.image === image)
        #expect(image.size.width > 0)
    }

    @Test("Downsamples to the view size by default and keeps the original size when disabled")
    func downsamplesToViewSize() async throws {
        let side: CGFloat = 400
        await load(try Self.writeImageFile(side: side))
        let downsampled = try #require(try box.result?.get())
        let pixelWidth = downsampled.size.width * downsampled.scale
        #expect(pixelWidth < side)
        #expect(pixelWidth <= imageView.bounds.width * imageView.traitCollection.displayScale)

        box.result = nil
        await load(try Self.writeImageFile(side: side), options: RemoteImageOptions(fadeDuration: 0, downsamplesToViewSize: false))
        let original = try #require(try box.result?.get())
        #expect(original.size.width * original.scale == side)
    }

    @Test("No downsampling for a zero-sized view or when disabled")
    func skipsDownsamplingWithoutSize() {
        let unsized = UIImageView()
        #expect(RemoteImageLoader.downsampleSize(for: unsized, options: RemoteImageOptions()) == nil)
        #expect(RemoteImageLoader.downsampleSize(for: imageView, options: RemoteImageOptions()) == imageView.bounds.size)
        #expect(RemoteImageLoader.downsampleSize(for: imageView, options: RemoteImageOptions(downsamplesToViewSize: false)) == nil)
    }

    @Test("Options map to transition, failure image and downsampling")
    func mapsOptions() {
        let none = RemoteImageOptions(fadeDuration: 0, downsamplesToViewSize: false)
        #expect(RemoteImageLoader.options(for: imageView, options: none).isEmpty)

        let all = RemoteImageOptions(failureImage: placeholder, fadeDuration: 0.3, downsamplesToViewSize: true)
        #expect(RemoteImageLoader.options(for: imageView, options: all).count == 4)
    }

    @Test("Local files and network URLs use different sources")
    func picksSource() throws {
        let file = RemoteImageLoader.source(for: URL(fileURLWithPath: "/tmp/a.png"))
        let network = RemoteImageLoader.source(for: try #require(URL(string: "https://example.com/a.png")))
        if case .provider = file {} else { Issue.record("file URL should use a data provider") }
        if case .network = network {} else { Issue.record("https URL should use the network") }
    }

    @Test("A nil URL shows the placeholder and reports invalidURL")
    func nilURL() {
        imageView.image = Self.makeImage(side: 3)
        imageView.wf_setImage(with: nil as URL?, placeholder: placeholder) { [box] in box.result = $0 }
        #expect(imageView.image === placeholder)
        #expect(box.result == .failure(.invalidURL))
    }

    @Test("Disallowed schemes are rejected", arguments: ["javascript:alert(1)", "ftp://example.com/a.png", "data:image/png;base64,AAAA", "no-scheme.png"])
    func rejectsDisallowedSchemes(link: String) {
        imageView.wf_setImage(with: link, placeholder: placeholder) { [box] in box.result = $0 }
        #expect(imageView.image === placeholder)
        #expect(box.result == .failure(.invalidURL))
    }

    @Test("https, http and file are allowed", arguments: ["https://example.com/a.png", "HTTP://example.com/a.png", "file:///tmp/a.png"])
    func allowsExpectedSchemes(link: String) throws {
        #expect(RemoteImageLoader.isAllowed(try #require(URL(string: link))))
    }

    @Test("String overload treats blank and nil as invalidURL and loads valid URLs")
    func stringOverload() async throws {
        imageView.wf_setImage(with: "  ", placeholder: placeholder) { [box] in box.result = $0 }
        #expect(box.result == .failure(.invalidURL))

        box.result = nil
        imageView.wf_setImage(with: nil as String?) { [box] in box.result = $0 }
        #expect(box.result == .failure(.invalidURL))
        #expect(imageView.image == nil)

        box.result = nil
        let url = try Self.writeImageFile(side: 8)
        imageView.wf_setImage(with: " \(url.absoluteString) ", options: RemoteImageOptions(fadeDuration: 0)) { [box] in
            box.result = $0
        }
        #expect(await waitUntil { box.result != nil })
        #expect((try? box.result?.get()) != nil)
    }

    @Test("A failed load reports failed and shows the failure image")
    func failureShowsFailureImage() async {
        let failureImage = Self.makeImage(side: 4)
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("wf-missing-\(UUID().uuidString).png")
        await load(missing, options: RemoteImageOptions(failureImage: failureImage, fadeDuration: 0))

        guard case .failure(.failed(let message)) = box.result else {
            Issue.record("expected .failed, got \(String(describing: box.result))")
            return
        }
        #expect(!message.isEmpty)
        #expect(imageView.image === failureImage)
    }

    @Test("A failed load without a failure image keeps the placeholder")
    func failureKeepsPlaceholder() async {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("wf-missing-\(UUID().uuidString).png")
        await load(missing)
        #expect(imageView.image === placeholder)
    }

    @Test("A new load cancels the previous one and the later image wins")
    func newLoadCancelsPrevious() async throws {
        let first = ResultBox()
        let firstURL = try Self.writeImageFile(side: 8)
        let secondURL = try Self.writeImageFile(side: 16)
        let options = RemoteImageOptions(fadeDuration: 0, downsamplesToViewSize: false)

        imageView.wf_setImage(with: firstURL, options: options) { first.result = $0 }
        imageView.wf_setImage(with: secondURL, options: options) { [box] in box.result = $0 }
        #expect(await waitUntil { box.result != nil })

        let shown = try #require(try box.result?.get())
        #expect(imageView.image === shown)
        #expect(shown.size.width * shown.scale == 16)
        // The first load was either cancelled or finished early; neither may override the final result.
        if let firstResult = first.result, case .failure(let error) = firstResult {
            #expect(error == .cancelled)
        }
    }

    @Test("wf_cancelImageLoad is a no-op when nothing is loading")
    func cancelIsSafe() {
        imageView.wf_cancelImageLoad()
        imageView.wf_cancelImageLoad()
        #expect(imageView.image == nil)
    }

    @Test("Being superseded maps to cancelled, everything else to failed")
    func mapsErrors() throws {
        let source = Source.network(try #require(URL(string: "https://example.com/a.png")))
        let superseded = KingfisherError.imageSettingError(
            reason: .notCurrentSourceTask(result: nil, error: nil, source: source)
        )
        #expect(RemoteImageLoader.map(.failure(superseded)) == .failure(.cancelled))

        guard case .failure(.failed(let message)) = RemoteImageLoader.map(.failure(.imageSettingError(reason: .emptySource))) else {
            Issue.record("emptySource should map to .failed")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test("Option defaults and cache clearing")
    func optionsAndCache() async {
        let options = RemoteImageOptions()
        #expect(options.failureImage == nil)
        #expect(options.fadeDuration == RemoteImageOptions.defaultFadeDuration)
        #expect(options.downsamplesToViewSize)

        RemoteImageCache.clearMemory()
        RemoteImageCache.clearDisk()
        let cleared = ResultBox()
        RemoteImageCache.clearDisk { cleared.result = .failure(.cancelled) }
        #expect(await waitUntil { cleared.result != nil })
    }
}
