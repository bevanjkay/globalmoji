import PickerCore
import SwiftUI

struct PickerView: View {
    @Bindable var model: PickerModel

    private let cell: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.items.isEmpty {
                Text("No matches for “\(model.query)”")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                grid
            }
            Divider()
            footer
        }
        .frame(width: cell * CGFloat(model.columns) + 24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            Text(":" + model.query)
                .font(.system(.body, design: .monospaced))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var grid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cell), spacing: 0), count: model.columns),
                    spacing: 0
                ) {
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            model.commit(item)
                        } label: {
                            Text(item.insertionText(skinTone: model.skinTone))
                                .font(.system(size: 24))
                                .frame(width: cell, height: cell)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(index == model.selectedIndex ? Color.accentColor.opacity(0.35) : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(item.id)
                        .onHover { hovering in
                            if hovering {
                                model.select(item)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: cell * 4 + 16)
            .onChange(of: model.selectedIndex) { _, _ in
                if let selected = model.selectedItem {
                    proxy.scrollTo(selected.id, anchor: .center)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let item = model.selectedItem {
                Text(item.insertionText(skinTone: model.skinTone)).font(.title3)
                Text(item.title).lineLimit(1)
                if let subtitle = item.subtitle {
                    Text(subtitle).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Text("↩ insert · esc close").font(.caption2).foregroundStyle(.tertiary)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
