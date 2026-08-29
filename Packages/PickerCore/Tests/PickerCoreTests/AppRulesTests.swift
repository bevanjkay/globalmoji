import PickerCore
import Testing

struct AppRulesTests {
    @Test func denyListBlocksListedAndPrefixMatches() {
        let rules = AppRules()
        #expect(rules.isEnabled(forBundleID: "com.tinyspeck.slackmacgap"))
        #expect(!rules.isEnabled(forBundleID: "com.apple.Terminal"))
        #expect(!rules.isEnabled(forBundleID: "com.1password.1password"))
        #expect(rules.isEnabled(forBundleID: nil))
    }

    @Test func allowListOnlyEnablesListed() {
        let rules = AppRules(mode: .allowList, bundleIDs: ["com.tinyspeck.slackmacgap"])
        #expect(rules.isEnabled(forBundleID: "com.tinyspeck.slackmacgap"))
        #expect(!rules.isEnabled(forBundleID: "com.apple.Notes"))
        #expect(!rules.isEnabled(forBundleID: nil))
    }
}
