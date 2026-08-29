import Foundation
import PickerCore
import Testing

struct SettingsTests {
    @Test func decodingFillsMissingKeysWithDefaults() throws {
        let data = Data(#"{"trigger": ";", "appRules": {"mode": "allowList", "bundleIDs": ["a.b"]}}"#.utf8)
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        #expect(settings.triggerCharacter == ";")
        #expect(settings.minimumCharacters == 2)
        #expect(settings.skinTone == .none)
        #expect(settings.appRules.mode == .allowList)
        #expect(settings.appRules.bundleIDs == ["a.b"])
    }

    @Test @MainActor func storeSavesOnChangeAndNotifies() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = SettingsStore(store: JSONStore(directory: directory))
        var notified: Settings?
        store.onChange = { notified = $0 }
        store.settings.skinTone = .medium
        #expect(notified?.skinTone == .medium)
        let reloaded = SettingsStore(store: JSONStore(directory: directory))
        #expect(reloaded.settings.skinTone == .medium)
        try FileManager.default.removeItem(at: directory)
    }
}
