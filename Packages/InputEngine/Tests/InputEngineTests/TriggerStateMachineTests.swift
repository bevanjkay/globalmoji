import InputEngine
import Testing

struct TriggerStateMachineTests {
    @Test func showsAfterMinimumCharacters() {
        var machine = TriggerStateMachine()
        #expect(machine.handle(character: ":", previousCharacterIsBoundary: true) == .none)
        #expect(machine.handle(character: "s", previousCharacterIsBoundary: false) == .none)
        #expect(machine.handle(character: "m", previousCharacterIsBoundary: false) == .show(query: "sm"))
        #expect(machine.typedLength == 3)
    }

    @Test func ignoresTriggerMidWord() {
        var machine = TriggerStateMachine()
        _ = machine.handle(character: ":", previousCharacterIsBoundary: false)
        #expect(!machine.isArmed)
    }

    @Test func spaceResetsAndHides() {
        var machine = TriggerStateMachine()
        _ = machine.handle(character: ":", previousCharacterIsBoundary: true)
        _ = machine.handle(character: "o", previousCharacterIsBoundary: false)
        _ = machine.handle(character: "k", previousCharacterIsBoundary: false)
        #expect(machine.handle(character: " ", previousCharacterIsBoundary: false) == .hide)
        #expect(!machine.isArmed)
    }

    @Test func backspaceBelowMinimumHides() {
        var machine = TriggerStateMachine()
        _ = machine.handle(character: ":", previousCharacterIsBoundary: true)
        _ = machine.handle(character: "o", previousCharacterIsBoundary: false)
        _ = machine.handle(character: "k", previousCharacterIsBoundary: false)
        #expect(machine.handleBackspace() == .hide)
        #expect(machine.handleBackspace() == .none)
        #expect(machine.handleBackspace() == .none)
        #expect(!machine.isArmed)
    }
}
