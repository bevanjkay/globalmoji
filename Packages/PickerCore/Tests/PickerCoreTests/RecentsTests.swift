import Foundation
import PickerCore
import Testing

struct RecentsTests {
    @Test func recordMovesToFrontAndCounts() {
        var recents = Recents()
        recents.record("a")
        recents.record("b")
        recents.record("a")
        #expect(recents.ids == ["a", "b"])
        #expect(recents.entries.first?.count == 2)
    }

    @Test func limitTrimsOldest() {
        var recents = Recents()
        recents.limit = 2
        for id in ["a", "b", "c"] {
            recents.record(id)
        }
        #expect(recents.ids == ["c", "b"])
    }

    @Test func boostFavoursMostRecent() {
        var recents = Recents()
        recents.record("old")
        recents.record("new")
        #expect(recents.boost(for: "new") > recents.boost(for: "old"))
        #expect(recents.boost(for: "old") > 0)
        #expect(recents.boost(for: "never") == 0)
        #expect(recents.boost(for: "new") < 1)
    }

    @Test @MainActor func storeRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = JSONStore(directory: directory)
        RecentsStore(store: store, file: "recents.json").record("1F600")
        let reloaded = RecentsStore(store: store, file: "recents.json")
        #expect(reloaded.recents.ids == ["1F600"])
        try FileManager.default.removeItem(at: directory)
    }
}
