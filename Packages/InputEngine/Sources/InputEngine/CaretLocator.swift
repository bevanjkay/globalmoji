import AppKit
import ApplicationServices

/// Finds where to show the picker: the caret of the focused text element, else the mouse.
public enum CaretLocator {
    /// Caret bounds in AppKit screen coordinates (origin bottom-left), if the focused element exposes them.
    @MainActor
    public static func caretRect() -> CGRect? {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused
        else { return nil }
        let axElement = unsafeDowncast(element, to: AXUIElement.self)

        var rangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axElement, kAXSelectedTextRangeAttribute as CFString, &rangeValue) ==
            .success,
            let rangeValue
        else { return nil }
        let axRange = unsafeDowncast(rangeValue, to: AXValue.self)
        var range = CFRange()
        guard AXValueGetValue(axRange, .cfRange, &range) else { return nil }
        // Zero-length ranges return empty bounds in many apps; measure the preceding character instead.
        if range.length == 0, range.location > 0 {
            range.location -= 1
            range.length = 1
        }
        guard let parameter = AXValueCreate(.cfRange, &range) else { return nil }
        var boundsValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            axElement,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            parameter,
            &boundsValue
        ) == .success, let boundsValue else { return nil }
        var bounds = CGRect.zero
        guard AXValueGetValue(unsafeDowncast(boundsValue, to: AXValue.self), .cgRect, &bounds),
              bounds.size != .zero
        else { return nil }
        return flipToAppKit(bounds)
    }

    /// Point to anchor the picker's top-left corner at, preferring the caret.
    @MainActor
    public static func anchorPoint() -> CGPoint {
        if let caret = caretRect() {
            return CGPoint(x: caret.minX, y: caret.minY - 4)
        }
        let mouse = NSEvent.mouseLocation
        return CGPoint(x: mouse.x, y: mouse.y - 16)
    }

    private static func flipToAppKit(_ rect: CGRect) -> CGRect {
        // AX reports top-left origin relative to the primary display.
        guard let primary = NSScreen.screens.first else { return rect }
        let flippedY = primary.frame.maxY - rect.maxY
        return CGRect(x: rect.minX, y: flippedY, width: rect.width, height: rect.height)
    }
}
