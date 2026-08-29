import AppKit
import CoreGraphics

/// Session-level CGEvent tap delivering key and mouse events on the main thread.
/// Requires Input Monitoring permission; see `Permissions`.
@MainActor
public final class KeyEventTap {
    /// Marker placed in `eventSourceUserData` on events we synthesise so the tap ignores them.
    static let syntheticMarker: Int64 = 0x474C_4F42 // "GLOB"

    public typealias Handler = (KeyEvent) -> Bool

    public var onKey: Handler?
    public var onMouseDown: (() -> Void)?
    public private(set) var isRunning = false

    private var port: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public enum TapError: Error {
        case creationFailed
    }

    public func start() throws {
        guard !isRunning else { return }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let tap = Unmanaged<KeyEventTap>.fromOpaque(userInfo).takeUnretainedValue()
                let swallow = MainActor.assumeIsolated { tap.process(type: type, event: event) }
                return swallow ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            throw TapError.creationFailed
        }
        self.port = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        isRunning = true
    }

    public func stop() {
        guard isRunning, let port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        self.port = nil
        runLoopSource = nil
        isRunning = false
    }

    /// Returns `true` if the event should be swallowed.
    private func process(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return false
        case .leftMouseDown, .rightMouseDown:
            onMouseDown?()
            return false
        case .keyDown:
            guard event.getIntegerValueField(.eventSourceUserData) != Self.syntheticMarker else { return false }
            return onKey?(Self.keyEvent(from: event)) ?? false
        default:
            return false
        }
    }

    static func keyEvent(from event: CGEvent) -> KeyEvent {
        KeyEvent(key(for: event), modifiers: modifiers(for: event.flags))
    }

    private static func modifiers(for flags: CGEventFlags) -> KeyEvent.Modifiers {
        var modifiers: KeyEvent.Modifiers = []
        if flags.contains(.maskShift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if flags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if flags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        return modifiers
    }

    private static let specialKeys: [Int64: KeyEvent.Key] = [
        51: .backspace, 53: .escape, 36: .enter, 76: .enter, 48: .tab,
        126: .up, 125: .down, 123: .left, 124: .right,
    ]

    private static func key(for event: CGEvent) -> KeyEvent.Key {
        if let special = specialKeys[event.getIntegerValueField(.keyboardEventKeycode)] {
            return special
        }
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &buffer)
        let string = String(utf16CodeUnits: buffer, count: length)
        guard let character = string.first, string.count == 1, !character.isNewline,
              character.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
        else { return .other }
        return .character(character)
    }
}
