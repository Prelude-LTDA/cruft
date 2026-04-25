import SwiftUI
import AppKit

/// A transparent NSView whose empty regions allow the user to drag the window.
/// Drop it as the deepest `.background(...)` on a chrome element (status
/// line, toolbar accessory) to get the Finder-style "drag from the status
/// bar" behavior. Interactive controls layered on top still hit-test first.
///
/// The `mouseDownCanMoveWindow` route tends not to fire when the view is
/// nested inside an NSHostingView — SwiftUI intercepts the event. Calling
/// `window.performDrag(with:)` directly from `mouseDown(with:)` works
/// unconditionally.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DraggableView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
