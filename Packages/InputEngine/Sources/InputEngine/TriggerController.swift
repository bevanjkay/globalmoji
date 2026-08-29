import Foundation

/// Receives picker lifecycle events from `TriggerController`.
@MainActor
public protocol TriggerControllerDelegate: AnyObject {
    /// Whether the trigger should arm for the given frontmost app.
    func triggerController(_ controller: TriggerController, shouldActivateFor bundleID: String?) -> Bool
    func triggerController(_ controller: TriggerController, present query: String)
    func triggerController(_ controller: TriggerController, update query: String)
    func triggerControllerDismiss(_ controller: TriggerController)
    /// Navigation/commit keys while the picker is visible. Return `true` to consume the event.
    func triggerController(_ controller: TriggerController, pickerHandle event: KeyEvent) -> Bool
}

/// Bridges raw key events to the trigger state machine and the picker UI.
/// Pure logic (no CoreGraphics) so it can be unit tested.
@MainActor
public final class TriggerController {
    public weak var delegate: TriggerControllerDelegate?
    public private(set) var isPresenting = false
    public private(set) var frontmostBundleID: String?

    private var machine: TriggerStateMachine
    private var previousCharacterIsBoundary = true
    private var activeForCurrentApp = true

    public init(configuration: TriggerStateMachine.Configuration = .init()) {
        machine = TriggerStateMachine(configuration: configuration)
    }

    public var configuration: TriggerStateMachine.Configuration {
        get { machine.configuration }
        set {
            machine = TriggerStateMachine(configuration: newValue)
            dismiss()
        }
    }

    /// Characters typed since the trigger (inclusive) that should be deleted before inserting.
    public var typedLength: Int {
        machine.typedLength
    }

    public var query: String {
        machine.query
    }

    /// Returns `true` if the event should be swallowed (not delivered to the frontmost app).
    public func handle(_ event: KeyEvent) -> Bool {
        if !event.modifiers.isDisjoint(with: [.command, .control]) {
            dismiss()
            previousCharacterIsBoundary = true
            return false
        }

        if isPresenting {
            switch event.key {
            case .escape:
                dismiss()
                return true
            case .enter, .tab, .up, .down, .left, .right:
                return delegate?.triggerController(self, pickerHandle: event) ?? false
            default:
                break
            }
        }

        switch event.key {
        case let .character(character):
            let action = machine.handle(character: character, previousCharacterIsBoundary: previousCharacterIsBoundary)
            previousCharacterIsBoundary = !(character.isLetter || character.isNumber)
            if machine.isArmed, machine.query.isEmpty, !activeForCurrentApp {
                machine.reset()
            }
            apply(action)
            return false
        case .backspace:
            apply(machine.handleBackspace())
            return false
        case .escape, .enter, .tab, .up, .down, .left, .right, .other:
            dismiss()
            previousCharacterIsBoundary = true
            return false
        }
    }

    public func frontmostAppChanged(bundleID: String?) {
        frontmostBundleID = bundleID
        activeForCurrentApp = delegate?.triggerController(self, shouldActivateFor: bundleID) ?? true
        dismiss()
        previousCharacterIsBoundary = true
    }

    public func mouseClicked() {
        dismiss()
        previousCharacterIsBoundary = true
    }

    /// Resets state after the picker has inserted a result (or the user cancelled).
    public func dismiss() {
        machine.reset()
        if isPresenting {
            isPresenting = false
            delegate?.triggerControllerDismiss(self)
        }
    }

    private func apply(_ action: TriggerStateMachine.Action) {
        switch action {
        case .none:
            break
        case let .show(query):
            if isPresenting {
                delegate?.triggerController(self, update: query)
            } else {
                isPresenting = true
                delegate?.triggerController(self, present: query)
            }
        case .hide:
            if isPresenting {
                isPresenting = false
                delegate?.triggerControllerDismiss(self)
            }
        }
    }
}
