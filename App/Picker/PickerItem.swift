import PickerCore

/// Anything the picker can display and insert. Emoji now; GIF and ASCII join in later milestones.
enum PickerItem: Identifiable, Hashable {
    case emoji(Emoji)

    var id: String {
        switch self {
        case let .emoji(emoji): "emoji:\(emoji.id)"
        }
    }

    var title: String {
        switch self {
        case let .emoji(emoji): emoji.name
        }
    }

    var subtitle: String? {
        switch self {
        case let .emoji(emoji): emoji.shortcodes.first.map { ":\($0):" }
        }
    }

    func insertionText(skinTone: SkinTone) -> String {
        switch self {
        case let .emoji(emoji): emoji.character(with: skinTone)
        }
    }
}
