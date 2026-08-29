import PickerCore
import Testing

struct EmojiCatalogTests {
    @Test func bundledCatalogLoadsAndIsOrdered() throws {
        let catalog = try EmojiCatalog.bundled()
        #expect(catalog.emoji.count > 1500)
        #expect(catalog.source.hasPrefix("emojibase-data@"))
        #expect(catalog.emoji.map(\.order) == catalog.emoji.map(\.order).sorted())
        #expect(catalog.emoji.first?.name == "grinning face")
    }

    @Test func shortcodeLookupMergesPresets() throws {
        let catalog = try EmojiCatalog.bundled()
        #expect(catalog.emoji(shortcode: "thumbsup")?.id == "1F44D")
        #expect(catalog.emoji(shortcode: "+1")?.id == "1F44D")
        #expect(catalog.emoji(shortcode: "grinning")?.id == "1F600")
    }

    @Test func skinTonesApplyOnlyWhereSupported() throws {
        let catalog = try EmojiCatalog.bundled()
        let wave = try #require(catalog.emoji(id: "1F44B"))
        #expect(wave.supportsSkinTones)
        #expect(wave.character(with: .none) == "👋")
        #expect(wave.character(with: .dark) == "👋🏿")
        let grin = try #require(catalog.emoji(id: "1F600"))
        #expect(!grin.supportsSkinTones)
        #expect(grin.character(with: .dark) == "😀")
    }

    @Test func componentsAndRegionalIndicatorsExcluded() throws {
        let catalog = try EmojiCatalog.bundled()
        #expect(catalog.emoji(id: "1F3FB") == nil)
        #expect(catalog.emoji(id: "1F1E6") == nil)
        #expect(catalog.emoji(shortcode: "flag_au")?.character == "🇦🇺")
    }
}
