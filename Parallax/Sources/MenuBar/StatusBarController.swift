import AppKit

final class StatusBarController {

    private let statusItem: NSStatusItem
    private let displayManager = DisplayManager.shared

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Parallax")
        }

        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "Connected Displays", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // Current displays
        let displays = displayManager.currentDisplays()

        if displays.isEmpty {
            let noDisplays = NSMenuItem(title: "No displays detected", action: nil, keyEquivalent: "")
            noDisplays.isEnabled = false
            menu.addItem(noDisplays)
        } else {
            for display in displays {
                let item = NSMenuItem(title: display.displayName, action: nil, keyEquivalent: "")
                item.isEnabled = false

                let detail = NSMenuItem(title: "  \(display.resolutionDescription)  •  Origin \(display.positionDescription)", action: nil, keyEquivalent: "")
                detail.isEnabled = false
                detail.indentationLevel = 1

                if let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular) as NSFont? {
                    detail.attributedTitle = NSAttributedString(
                        string: detail.title,
                        attributes: [
                            .font: font,
                            .foregroundColor: NSColor.secondaryLabelColor
                        ]
                    )
                }

                menu.addItem(item)
                menu.addItem(detail)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Saved profiles placeholder (Phase 2)
        let profilesHeader = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        profilesHeader.isEnabled = false
        menu.addItem(profilesHeader)

        let noProfiles = NSMenuItem(title: "  No saved profiles", action: nil, keyEquivalent: "")
        noProfiles.isEnabled = false
        menu.addItem(noProfiles)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Parallax", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }
}
