//
//  NativeMenuBarDragSource.swift
//  Ice
//

import SwiftUI

/// AppKit owns the drag gesture, as in the legacy layout editor, while the
/// separate SwiftUI menu remains available for accessible section assignment.
struct NativeMenuBarDragSource: NSViewRepresentable {
    let id: String
    let name: String
    let icon: NSImage?

    func makeNSView(context: Context) -> DragView { DragView() }

    func updateNSView(_ view: DragView, context: Context) {
        view.itemID = id
        view.itemName = name
        view.icon = icon
    }

    final class DragView: NSView, NSDraggingSource {
        var itemID = ""
        var itemName = ""
        var icon: NSImage?

        override func mouseDown(with event: NSEvent) { }

        override func mouseDragged(with event: NSEvent) {
            let item = NSPasteboardItem()
            item.setData(Data(itemID.utf8), forType: NSPasteboard.PasteboardType(NativeMenuBarDrag.type.identifier))
            let draggingItem = NSDraggingItem(pasteboardWriter: item)
            let image = NSImage(size: bounds.size, flipped: false) { [self] rect in
                NSColor.controlBackgroundColor.setFill()
                NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7).fill()
                icon?.draw(in: NSRect(x: 9, y: (rect.height - 28) / 2, width: 28, height: 28))
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byTruncatingTail
                (itemName as NSString).draw(in: NSRect(x: 44, y: (rect.height - 18) / 2, width: max(0, rect.width - 48), height: 18), withAttributes: [
                    .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraph,
                ])
                return true
            }
            draggingItem.setDraggingFrame(bounds, contents: image)
            beginDraggingSession(with: [draggingItem], event: event, source: self)
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            context == .withinApplication ? .move : []
        }
    }
}
