import AppKit
import SwiftUI

/// Floating, non-activating panel so the target app keeps keyboard focus.
/// Keys reach the picker via the event tap, not through this window.
@MainActor
final class PickerPanel: NSPanel {
    init(model: PickerModel) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        contentViewController = NSHostingController(rootView: PickerView(model: model))
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    /// Shows the panel with its top-left at `anchor`, kept on screen.
    func present(at anchor: CGPoint) {
        contentViewController?.view.layoutSubtreeIfNeeded()
        let size = contentViewController?.view.fittingSize ?? frame.size
        var origin = CGPoint(x: anchor.x, y: anchor.y - size.height)
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            if origin.x + size.width > visible.maxX {
                origin.x = visible.maxX - size.width
            }
            if origin.x < visible.minX {
                origin.x = visible.minX
            }
            if origin.y < visible.minY {
                origin.y = anchor.y + 24
            }
        }
        setFrame(CGRect(origin: origin, size: size), display: true)
        orderFrontRegardless()
    }

    func dismiss() {
        orderOut(nil)
    }

    func contains(screenPoint: CGPoint) -> Bool {
        isVisible && frame.contains(screenPoint)
    }
}
