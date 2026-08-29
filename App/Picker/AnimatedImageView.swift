import AppKit
import SwiftUI

/// Animated GIF preview backed by `NSImageView`, which plays GIF frames natively.
struct AnimatedImageView: NSViewRepresentable {
    let url: URL

    func makeNSView(context _: Context) -> NSImageView {
        let view = NSImageView()
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        guard context.coordinator.url != url else { return }
        context.coordinator.url = url
        view.image = nil
        context.coordinator.task?.cancel()
        context.coordinator.task = Task { [url] in
            guard let image = await GIFImageCache.shared.image(for: url), !Task.isCancelled else { return }
            view.image = image
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        var url: URL?
        var task: Task<Void, Never>?
    }
}

@MainActor
final class GIFImageCache {
    static let shared = GIFImageCache()
    private let cache = NSCache<NSURL, NSImage>()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 50 << 20, diskCapacity: 200 << 20)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        cache.countLimit = 200
    }

    func image(for url: URL) async -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        guard let (data, _) = try? await session.data(from: url), let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }

    func data(for url: URL) async -> Data? {
        try? await session.data(from: url).0
    }
}
