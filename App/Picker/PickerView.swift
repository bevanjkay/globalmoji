import PickerCore
import SwiftUI

struct PickerView: View {
    @Bindable var model: PickerModel

    private let cell: CGFloat = 36
    private let width: CGFloat = 36 * 8 + 24

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: width)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            Text(":" + model.query)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            Spacer()
            HStack(spacing: 2) {
                ForEach(PickerMode.allCases, id: \.self) { mode in
                    Button(mode.title) { model.setMode(mode) }
                        .buttonStyle(.plain)
                        .font(.caption.weight(mode == model.mode ? .semibold : .regular))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(mode == model.mode ? Color.accentColor.opacity(0.25) : .clear)
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if model.mode == .gif {
            gifContent
        } else if model.items.isEmpty {
            Text("No matches for “\(model.query)”")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else if model.mode == .ascii {
            list
        } else {
            grid
        }
    }

    @ViewBuilder
    private var gifContent: some View {
        if let error = model.gifError {
            Text(error)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
        } else if model.items.isEmpty {
            (model.isLoadingGIFs ? ProgressView().controlSize(.small).eraseToAnyView()
                : Text("No GIFs for “\(model.query)”").foregroundStyle(.secondary).eraseToAnyView())
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            gifGrid
        }
    }

    private var gifGrid: some View {
        let size = (width - 16) / CGFloat(model.columns)
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: model.columns),
                    spacing: 0
                ) {
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                        if case let .gif(gif) = item {
                            Button {
                                model.commit(item)
                            } label: {
                                AnimatedImageView(url: gif.previewURL)
                                    .frame(width: size - 6, height: size - 6)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(3)
                                    .background(selectionBackground(selected: index == model.selectedIndex))
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
                }
                .padding(8)
            }
            .frame(maxHeight: size * 3 + 16)
            .onChange(of: model.selectedIndex) { _, _ in scrollToSelection(proxy) }
        }
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
                                .background(selectionBackground(selected: index == model.selectedIndex))
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
            .onChange(of: model.selectedIndex) { _, _ in scrollToSelection(proxy) }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            model.commit(item)
                        } label: {
                            HStack {
                                Text(item.insertionText(skinTone: model.skinTone))
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                Spacer()
                                Text(item.title).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .background(selectionBackground(selected: index == model.selectedIndex))
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
            .frame(maxHeight: 30 * 5 + 16)
            .onChange(of: model.selectedIndex) { _, _ in scrollToSelection(proxy) }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let item = model.selectedItem {
                if model.mode == .emoji {
                    Text(item.insertionText(skinTone: model.skinTone)).font(.title3)
                }
                Text(item.title).lineLimit(1)
                if let subtitle = item.subtitle {
                    Text(subtitle).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if model.mode == .gif {
                Text("Powered by GIPHY").font(.caption2).foregroundStyle(.tertiary)
            } else {
                Text("↩ insert · ⇥ mode · esc close").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func selectionBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(selected ? Color.accentColor.opacity(0.35) : .clear)
    }

    private func scrollToSelection(_ proxy: ScrollViewProxy) {
        if let selected = model.selectedItem {
            proxy.scrollTo(selected.id, anchor: .center)
        }
    }
}

private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
