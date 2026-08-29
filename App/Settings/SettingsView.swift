import PickerCore
import SwiftUI

struct SettingsView: View {
    let store: SettingsStore

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsView(store: store)
            }
            Tab("Apps", systemImage: "app.badge.checkmark") {
                AppRulesSettingsView(store: store)
            }
            Tab("GIFs", systemImage: "photo.on.rectangle.angled") {
                GIFSettingsView(store: store)
            }
        }
        .frame(width: 520, height: 420)
    }
}
