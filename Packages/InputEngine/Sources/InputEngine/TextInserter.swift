import AppKit
import CoreGraphics

/// Deletes the typed trigger text and inserts the chosen result into the frontmost app.
@MainActor
public final class TextInserter {
    public enum Strategy: String, Codable, CaseIterable, Sendable {
        /// Put the text on the pasteboard and send ⌘V, then restore the pasteboard. Most compatible.
        case paste
        /// Post keyboard events carrying the unicode string. Leaves the pasteboard alone but some
        /// apps (notably Electron) drop or reorder them.
        case type
    }

    public var strategy: Strategy = .paste
    /// Delay between synthesised key events; some apps drop events posted back-to-back.
    public var keyInterval: Duration = .milliseconds(4)
    public var pasteboardRestoreDelay: Duration = .milliseconds(400)

    private let source = CGEventSource(stateID: .combinedSessionState)

    public init() {}

    public func replaceTyped(count: Int, with text: String) async {
        await deleteBackward(count: count)
        await insert(text)
    }

    public func insert(_ text: String) async {
        switch strategy {
        case .paste: await paste(string: text)
        case .type: await type(text)
        }
    }

    /// Pastes an image (e.g. a GIF) with an optional URL fallback for apps that ignore image data.
    public func paste(imageData: Data, type: NSPasteboard.PasteboardType, fallbackURL: URL?) async {
        await withPasteboardSnapshot { pasteboard in
            let item = NSPasteboardItem()
            item.setData(imageData, forType: type)
            if let fallbackURL {
                item.setString(fallbackURL.absoluteString, forType: .string)
            }
            pasteboard.writeObjects([item])
        }
    }

    public func deleteBackward(count: Int) async {
        for _ in 0 ..< max(count, 0) {
            post(keyCode: 51, flags: [])
            try? await Task.sleep(for: keyInterval)
        }
    }

    private func paste(string: String) async {
        await withPasteboardSnapshot { pasteboard in
            pasteboard.setString(string, forType: .string)
        }
    }

    private func withPasteboardSnapshot(_ write: (NSPasteboard) -> Void) async {
        let pasteboard = NSPasteboard.general
        var snapshot: [NSPasteboardItem] = []
        for item in pasteboard.pasteboardItems ?? [] {
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            snapshot.append(copy)
        }
        pasteboard.clearContents()
        write(pasteboard)
        try? await Task.sleep(for: keyInterval)
        post(keyCode: 9, flags: .maskCommand) // ⌘V
        try? await Task.sleep(for: pasteboardRestoreDelay)
        pasteboard.clearContents()
        if !snapshot.isEmpty {
            pasteboard.writeObjects(snapshot)
        }
    }

    private func type(_ text: String) async {
        // keyboardSetUnicodeString accepts at most 20 UTF-16 units per event.
        var units = Array(text.utf16)
        while !units.isEmpty {
            let chunk = Array(units.prefix(20))
            units.removeFirst(chunk.count)
            for isDown in [true, false] {
                guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: isDown) else { continue }
                chunk.withUnsafeBufferPointer { buffer in
                    event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
                }
                mark(event)
                event.post(tap: .cgSessionEventTap)
            }
            try? await Task.sleep(for: keyInterval)
        }
    }

    private func post(keyCode: CGKeyCode, flags: CGEventFlags) {
        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: isDown)
            else { continue }
            event.flags = flags
            mark(event)
            event.post(tap: .cgSessionEventTap)
        }
    }

    private func mark(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: KeyEventTap.syntheticMarker)
    }
}
