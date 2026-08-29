import InputEngine
import Testing

@MainActor
final class RecordingDelegate: TriggerControllerDelegate {
    enum Event: Equatable { case present(String), update(String), dismiss, picker(KeyEvent) }
    var events: [Event] = []
    var disabledBundleIDs: Set<String> = []
    var consumesPickerKeys = true

    func triggerController(_: TriggerController, shouldActivateFor bundleID: String?) -> Bool {
        bundleID.map { !disabledBundleIDs.contains($0) } ?? true
    }

    func triggerController(_: TriggerController, present query: String) {
        events.append(.present(query))
    }

    func triggerController(_: TriggerController, update query: String) {
        events.append(.update(query))
    }

    func triggerControllerDismiss(_: TriggerController) {
        events.append(.dismiss)
    }

    func triggerController(_: TriggerController, pickerHandle event: KeyEvent) -> Bool {
        events.append(.picker(event))
        return consumesPickerKeys
    }
}

@MainActor
struct TriggerControllerTests {
    func make() -> (TriggerController, RecordingDelegate) {
        let controller = TriggerController()
        let delegate = RecordingDelegate()
        controller.delegate = delegate
        return (controller, delegate)
    }

    func type(_ text: String, into controller: TriggerController) {
        for character in text {
            _ = controller.handle(.char(character))
        }
    }

    @Test func presentsThenUpdates() {
        let (controller, delegate) = make()
        type(":smi", into: controller)
        #expect(delegate.events == [.present("sm"), .update("smi")])
        #expect(controller.isPresenting)
        #expect(controller.typedLength == 4)
    }

    @Test func typedCharactersAreNeverSwallowed() {
        let (controller, _) = make()
        #expect(!controller.handle(.char(":")))
        #expect(!controller.handle(.char("o")))
        #expect(!controller.handle(.char("k")))
    }

    @Test func colonMidWordDoesNotArm() {
        let (controller, delegate) = make()
        type("http:ab", into: controller)
        #expect(delegate.events.isEmpty)
        #expect(!controller.isPresenting)
    }

    @Test func escapeDismissesAndIsSwallowed() {
        let (controller, delegate) = make()
        type(":ok", into: controller)
        #expect(controller.handle(KeyEvent(.escape)))
        #expect(delegate.events.last == .dismiss)
        #expect(!controller.isPresenting)
    }

    @Test func navigationKeysGoToPickerWhileVisible() {
        let (controller, delegate) = make()
        type(":ok", into: controller)
        #expect(controller.handle(KeyEvent(.down)))
        #expect(controller.handle(KeyEvent(.enter)))
        #expect(delegate.events.suffix(2) == [.picker(KeyEvent(.down)), .picker(KeyEvent(.enter))])
    }

    @Test func navigationKeysPassThroughWhenHidden() {
        let (controller, delegate) = make()
        #expect(!controller.handle(KeyEvent(.down)))
        #expect(delegate.events.isEmpty)
    }

    @Test func commandShortcutsResetAndPassThrough() {
        let (controller, delegate) = make()
        type(":ok", into: controller)
        #expect(!controller.handle(KeyEvent(.character("a"), modifiers: .command)))
        #expect(delegate.events.last == .dismiss)
    }

    @Test func disabledAppNeverPresents() {
        let (controller, delegate) = make()
        delegate.disabledBundleIDs = ["com.apple.Terminal"]
        controller.frontmostAppChanged(bundleID: "com.apple.Terminal")
        type(":ok", into: controller)
        #expect(delegate.events.isEmpty)
        controller.frontmostAppChanged(bundleID: "com.apple.Notes")
        type(":ok", into: controller)
        #expect(delegate.events == [.present("ok")])
    }

    @Test func appSwitchAndClickDismiss() {
        let (controller, delegate) = make()
        type(":ok", into: controller)
        controller.frontmostAppChanged(bundleID: "com.apple.Notes")
        #expect(delegate.events.last == .dismiss)
        type(":ok", into: controller)
        controller.mouseClicked()
        #expect(delegate.events.filter { $0 == .dismiss }.count == 2)
    }

    @Test func backspaceToBelowMinimumHides() {
        let (controller, delegate) = make()
        type(":ok", into: controller)
        #expect(!controller.handle(KeyEvent(.backspace)))
        #expect(delegate.events.last == .dismiss)
        #expect(!controller.isPresenting)
    }
}
