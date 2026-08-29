import Foundation

/// Tracks typed characters after the trigger key and decides when the picker should show.
/// Pure logic; the event tap feeds it characters and acts on the returned `Action`.
public struct TriggerStateMachine: Sendable {
    public enum Action: Equatable, Sendable {
        case none
        case show(query: String)
        case hide
    }

    public struct Configuration: Sendable {
        public var trigger: Character
        public var minimumCharacters: Int

        public init(trigger: Character = ":", minimumCharacters: Int = 2) {
            self.trigger = trigger
            self.minimumCharacters = minimumCharacters
        }
    }

    public private(set) var isArmed = false
    public private(set) var query = ""
    public let configuration: Configuration

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    /// Number of characters typed since (and including) the trigger, i.e. how many backspaces
    /// are needed to remove the typed text before inserting a result.
    public var typedLength: Int {
        isArmed ? query.count + 1 : 0
    }

    public mutating func handle(character: Character, previousCharacterIsBoundary: Bool) -> Action {
        if !isArmed {
            if character == configuration.trigger, previousCharacterIsBoundary {
                isArmed = true
                query = ""
            }
            return .none
        }
        if Self.isQueryCharacter(character) {
            query.append(character)
            return query.count >= configuration.minimumCharacters ? .show(query: query) : .none
        }
        return reset()
    }

    public mutating func handleBackspace() -> Action {
        guard isArmed else { return .none }
        if query.isEmpty {
            return reset()
        }
        let wasShowing = query.count >= configuration.minimumCharacters
        query.removeLast()
        if query.count >= configuration.minimumCharacters {
            return .show(query: query)
        }
        return wasShowing ? .hide : .none
    }

    @discardableResult
    public mutating func reset() -> Action {
        let wasShowing = isArmed && query.count >= configuration.minimumCharacters
        isArmed = false
        query = ""
        return wasShowing ? .hide : .none
    }

    static func isQueryCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_" || character == "-" || character == "+"
    }
}
