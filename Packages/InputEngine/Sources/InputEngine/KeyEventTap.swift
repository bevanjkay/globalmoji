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
    /// Called when the system disabled the key tap repeatedly (the process stalled) and we gave up.
    public var onStalled: (() -> Void)?
    public private(set) var isRunning = false

    /// Active tap: only `keyDown`, so a stalled process can never hold up clicks.
    private var keyTap: Tap?
    /// Passive tap: mouse buttons are observed, never intercepted.
    private var mouseTap: Tap?
    private var timeoutTimestamps: [ContinuousClock.Instant] = []
    private let maxTimeouts = 3
    private let timeoutWindow: Duration = .seconds(10)

    public init() {}

    public enum TapError: Error {
        case creationFailed
    }

    public func start() throws {
        guard !isRunning else { return }
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let keyTap = Tap.create(
            mask: 1 << CGEventType.keyDown.rawValue,
            options: .defaultTap,
            userInfo: userInfo
        ) else {
            throw TapError.creationFailed
        }
        let mouseMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
        let mouseTap = Tap.create(mask: mouseMask, options: .listenOnly, userInfo: userInfo)
        self.keyTap = keyTap
        self.mouseTap = mouseTap
        keyTap.enable()
        mouseTap?.enable()
        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        keyTap?.disable()
        mouseTap?.disable()
        keyTap = nil
        mouseTap = nil
        timeoutTimestamps.removeAll()
        isRunning = false
    }

    /// Returns `true` if the event should be swallowed.
    private func process(type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            handleDisabled()
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

    /// macOS disables a tap whose process stops servicing events. Re-enable a few times, then give
    /// up rather than freezing the user's input in a loop.
    private func handleDisabled() {
        let now = ContinuousClock.now
        timeoutTimestamps.removeAll { now - $0 > timeoutWindow }
        timeoutTimestamps.append(now)
        if timeoutTimestamps.count > maxTimeouts {
            stop()
            onStalled?()
            return
        }
        keyTap?.enable()
        mouseTap?.enable()
    }

    @MainActor
    private final class Tap {
        let port: CFMachPort
        let source: CFRunLoopSource

        init(port: CFMachPort) {
            self.port = port
            source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        static func create(mask: CGEventMask, options: CGEventTapOptions, userInfo: UnsafeMutableRawPointer) -> Tap? {
            guard let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: options,
                eventsOfInterest: mask,
                callback: { _, type, event, userInfo in
                    guard let userInfo else { return Unmanaged.passUnretained(event) }
                    let tap = Unmanaged<KeyEventTap>.fromOpaque(userInfo).takeUnretainedValue()
                    let swallow = MainActor.assumeIsolated { tap.process(type: type, event: event) }
                    return swallow ? nil : Unmanaged.passUnretained(event)
                },
                userInfo: userInfo
            ) else { return nil }
            return Tap(port: port)
        }

        func enable() {
            CGEvent.tapEnable(tap: port, enable: true)
        }

        func disable() {
            CGEvent.tapEnable(tap: port, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
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
