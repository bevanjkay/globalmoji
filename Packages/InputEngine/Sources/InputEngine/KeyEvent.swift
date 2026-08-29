import Foundation

/// Normalised keyboard event fed into `TriggerController`, independent of CoreGraphics.
public struct KeyEvent: Equatable, Sendable {
    public enum Key: Equatable, Sendable {
        case character(Character)
        case backspace
        case escape
        case enter
        case tab
        case up, down, left, right
        case other
    }

    public struct Modifiers: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let shift = Modifiers(rawValue: 1 << 0)
        public static let control = Modifiers(rawValue: 1 << 1)
        public static let option = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)
    }

    public var key: Key
    public var modifiers: Modifiers

    public init(_ key: Key, modifiers: Modifiers = []) {
        self.key = key
        self.modifiers = modifiers
    }

    public static func char(_ character: Character) -> KeyEvent {
        KeyEvent(.character(character))
    }
}
