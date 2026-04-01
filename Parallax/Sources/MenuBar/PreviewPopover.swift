import AppKit

final class PreviewPopover: NSPopover {

    init(arrangements: [DisplayArrangement], highlightProfile: String?) {
        super.init()
        self.behavior = .transient
        self.contentViewController = PreviewViewController(
            arrangements: arrangements,
            highlightProfile: highlightProfile
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class PreviewViewController: NSViewController {

    private let arrangements: [DisplayArrangement]
    private let highlightProfile: String?

    init(arrangements: [DisplayArrangement], highlightProfile: String?) {
        self.arrangements = arrangements
        self.highlightProfile = highlightProfile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 200))
        let previewView = DisplayPreviewView(
            arrangements: arrangements,
            highlightProfile: highlightProfile
        )
        previewView.frame = container.bounds
        previewView.autoresizingMask = [.width, .height]
        container.addSubview(previewView)
        self.view = container
    }
}

final class DisplayPreviewView: NSView {

    private let arrangements: [DisplayArrangement]
    private let highlightProfile: String?

    init(arrangements: [DisplayArrangement], highlightProfile: String?) {
        self.arrangements = arrangements
        self.highlightProfile = highlightProfile
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !arrangements.isEmpty else { return }

        let padding: CGFloat = 20

        // Find bounding box of all displays in global coordinates
        var minX = Int32.max, minY = Int32.max
        var maxX = Int32.min, maxY = Int32.min
        for a in arrangements {
            minX = min(minX, a.originX)
            minY = min(minY, a.originY)
            maxX = max(maxX, a.originX + Int32(a.width))
            maxY = max(maxY, a.originY + Int32(a.height))
        }

        let totalWidth = CGFloat(maxX - minX)
        let totalHeight = CGFloat(maxY - minY)
        guard totalWidth > 0, totalHeight > 0 else { return }

        let drawArea = bounds.insetBy(dx: padding, dy: padding)
        let scale = min(drawArea.width / totalWidth, drawArea.height / totalHeight)

        let scaledTotalWidth = totalWidth * scale
        let scaledTotalHeight = totalHeight * scale
        let offsetX = drawArea.minX + (drawArea.width - scaledTotalWidth) / 2
        let offsetY = drawArea.minY + (drawArea.height - scaledTotalHeight) / 2

        for arrangement in arrangements {
            let x = CGFloat(arrangement.originX - minX) * scale + offsetX
            // Flip Y: CoreGraphics has Y going down, NSView has Y going up
            let y = CGFloat(maxY - arrangement.originY - Int32(arrangement.height)) * scale + offsetY
            let w = CGFloat(arrangement.width) * scale
            let h = CGFloat(arrangement.height) * scale

            let rect = NSRect(x: x, y: y, width: w, height: h)

            // Fill
            let fillColor: NSColor = arrangement.isPrimary
                ? NSColor.controlAccentColor.withAlphaComponent(0.2)
                : NSColor.secondaryLabelColor.withAlphaComponent(0.1)
            fillColor.setFill()
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            path.fill()

            // Border
            let borderColor: NSColor = arrangement.isPrimary
                ? NSColor.controlAccentColor
                : NSColor.secondaryLabelColor.withAlphaComponent(0.5)
            borderColor.setStroke()
            path.lineWidth = arrangement.isPrimary ? 2.0 : 1.0
            path.stroke()

            // Label
            let label = arrangement.displayID.isBuiltin ? "Built-in" : "\(arrangement.width)×\(arrangement.height)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            let str = NSAttributedString(string: label, attributes: attrs)
            let strSize = str.size()
            let strPoint = NSPoint(
                x: rect.midX - strSize.width / 2,
                y: rect.midY - strSize.height / 2
            )
            str.draw(at: strPoint)
        }

        // Title
        if let title = highlightProfile {
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
            let titleSize = titleStr.size()
            titleStr.draw(at: NSPoint(x: bounds.midX - titleSize.width / 2, y: bounds.maxY - padding + 2))
        }
    }
}
