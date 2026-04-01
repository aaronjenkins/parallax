import AppKit
import ServiceManagement

final class StatusBarController: NSObject {

    private let statusItem: NSStatusItem
    private let displayManager = DisplayManager.shared
    private let profileStore = ProfileStore.shared
    private var activePopover: PreviewPopover?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let icon = NSImage(named: "MenuBarIcon")
            icon?.isTemplate = true
            button.image = icon
        }

        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        let currentDisplays = displayManager.currentDisplays()
        let profiles = profileStore.load()

        // --- Connected Displays ---
        let headerItem = NSMenuItem(title: "Connected Displays", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        if currentDisplays.isEmpty {
            let noDisplays = NSMenuItem(title: "No displays detected", action: nil, keyEquivalent: "")
            noDisplays.isEnabled = false
            menu.addItem(noDisplays)
        } else {
            for display in currentDisplays {
                let item = NSMenuItem(title: display.displayName, action: nil, keyEquivalent: "")
                item.isEnabled = false

                let detailText = "  \(display.resolutionDescription)  •  Origin \(display.positionDescription)"
                let detail = NSMenuItem(title: detailText, action: nil, keyEquivalent: "")
                detail.isEnabled = false
                detail.indentationLevel = 1
                detail.attributedTitle = NSAttributedString(
                    string: detailText,
                    attributes: [
                        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]
                )

                menu.addItem(item)
                menu.addItem(detail)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // --- Profiles ---
        let profilesHeader = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        profilesHeader.isEnabled = false
        menu.addItem(profilesHeader)

        if profiles.isEmpty {
            let noProfiles = NSMenuItem(title: "  No saved profiles", action: nil, keyEquivalent: "")
            noProfiles.isEnabled = false
            menu.addItem(noProfiles)
        } else {
            for profile in profiles {
                let isActive = profile.matches(current: currentDisplays)
                var title = profile.name
                if let idx = profile.shortcutIndex {
                    title += "  ⌃⌥\(idx)"
                }

                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")

                if isActive {
                    item.state = .on
                }

                // Submenu for each profile: Apply, Preview, Rename, Assign Shortcut, Delete
                let submenu = NSMenu()

                let applyItem = NSMenuItem(title: "Apply", action: #selector(applyProfile(_:)), keyEquivalent: "")
                applyItem.target = self
                applyItem.representedObject = profile.id
                submenu.addItem(applyItem)

                let previewItem = NSMenuItem(title: "Preview", action: #selector(showPreview(_:)), keyEquivalent: "")
                previewItem.target = self
                previewItem.representedObject = profile
                submenu.addItem(previewItem)

                submenu.addItem(NSMenuItem.separator())

                let renameItem = NSMenuItem(title: "Rename...", action: #selector(renameProfile(_:)), keyEquivalent: "")
                renameItem.target = self
                renameItem.representedObject = profile.id
                submenu.addItem(renameItem)

                // Shortcut assignment submenu
                let shortcutMenu = NSMenu()
                let shortcutItem = NSMenuItem(title: "Assign Shortcut", action: nil, keyEquivalent: "")

                let noneItem = NSMenuItem(title: "None", action: #selector(assignShortcut(_:)), keyEquivalent: "")
                noneItem.target = self
                noneItem.representedObject = ShortcutAssignment(profileID: profile.id, index: nil)
                if profile.shortcutIndex == nil { noneItem.state = .on }
                shortcutMenu.addItem(noneItem)

                shortcutMenu.addItem(NSMenuItem.separator())

                for i in 1...9 {
                    let keyItem = NSMenuItem(title: "⌃⌥\(i)", action: #selector(assignShortcut(_:)), keyEquivalent: "")
                    keyItem.target = self
                    keyItem.representedObject = ShortcutAssignment(profileID: profile.id, index: i)
                    if profile.shortcutIndex == i { keyItem.state = .on }
                    shortcutMenu.addItem(keyItem)
                }

                shortcutItem.submenu = shortcutMenu
                submenu.addItem(shortcutItem)

                submenu.addItem(NSMenuItem.separator())

                let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteProfile(_:)), keyEquivalent: "")
                deleteItem.target = self
                deleteItem.representedObject = profile.id
                submenu.addItem(deleteItem)

                item.submenu = submenu
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // --- Save Current ---
        let saveItem = NSMenuItem(title: "Save Current Arrangement...", action: #selector(saveCurrentArrangement), keyEquivalent: "s")
        saveItem.target = self
        menu.addItem(saveItem)

        menu.addItem(NSMenuItem.separator())

        // --- Launch at Login ---
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // --- Quit ---
        let quitItem = NSMenuItem(title: "Quit Parallax", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Profile Actions

    @objc private func applyProfile(_ sender: NSMenuItem) {
        guard let profileID = sender.representedObject as? UUID else { return }
        let profiles = profileStore.load()
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return }

        let errors = displayManager.apply(profile: profile)
        if !errors.isEmpty {
            showAlert(
                title: "Some displays could not be configured",
                message: errors.map(\.description).joined(separator: "\n")
            )
        }

        // Rebuild menu after a brief delay to let displays settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.rebuildMenu()
        }
    }

    func applyProfileByShortcutIndex(_ index: Int) {
        let profiles = profileStore.load()
        guard let profile = profiles.first(where: { $0.shortcutIndex == index }) else { return }

        let errors = displayManager.apply(profile: profile)
        if !errors.isEmpty {
            showAlert(
                title: "Some displays could not be configured",
                message: errors.map(\.description).joined(separator: "\n")
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.rebuildMenu()
        }
    }

    @objc private func showPreview(_ sender: NSMenuItem) {
        guard let profile = sender.representedObject as? DisplayProfile else { return }
        guard let button = statusItem.button else { return }

        activePopover?.close()
        let popover = PreviewPopover(arrangements: profile.arrangements, highlightProfile: profile.name)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        activePopover = popover
    }

    @objc private func saveCurrentArrangement() {
        let currentDisplays = displayManager.currentDisplays()
        guard !currentDisplays.isEmpty else {
            showAlert(title: "No Displays", message: "No active displays detected.")
            return
        }

        let alert = NSAlert()
        alert.messageText = "Save Current Arrangement"
        alert.informativeText = "Enter a name for this display profile:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.placeholderString = "e.g., Monitor Above, Desk Setup"
        alert.accessoryView = textField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let name = textField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            showAlert(title: "Invalid Name", message: "Profile name cannot be empty.")
            return
        }

        let profile = DisplayProfile(name: name, arrangements: currentDisplays)
        profileStore.add(profile)
        rebuildMenu()
    }

    @objc private func renameProfile(_ sender: NSMenuItem) {
        guard let profileID = sender.representedObject as? UUID else { return }
        let profiles = profileStore.load()
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return }

        let alert = NSAlert()
        alert.messageText = "Rename Profile"
        alert.informativeText = "Enter a new name:"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.stringValue = profile.name
        alert.accessoryView = textField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let newName = textField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }

        profileStore.rename(id: profileID, to: newName)
        rebuildMenu()
    }

    @objc private func deleteProfile(_ sender: NSMenuItem) {
        guard let profileID = sender.representedObject as? UUID else { return }
        let profiles = profileStore.load()
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return }

        let alert = NSAlert()
        alert.messageText = "Delete Profile"
        alert.informativeText = "Are you sure you want to delete \"\(profile.name)\"?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        profileStore.delete(id: profileID)
        rebuildMenu()
    }

    @objc private func assignShortcut(_ sender: NSMenuItem) {
        guard let assignment = sender.representedObject as? ShortcutAssignment else { return }
        profileStore.updateShortcutIndex(id: assignment.profileID, index: assignment.index)
        rebuildMenu()
    }

    // MARK: - Launch at Login

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if sender.state == .on {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            showAlert(title: "Launch at Login", message: "Failed to update: \(error.localizedDescription)")
        }
        rebuildMenu()
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}

private struct ShortcutAssignment {
    let profileID: UUID
    let index: Int?
}
