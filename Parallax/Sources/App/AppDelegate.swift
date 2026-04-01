import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var displayChangeMonitor: DisplayChangeMonitor?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        displayChangeMonitor = DisplayChangeMonitor { [weak self] in
            self?.statusBarController?.rebuildMenu()
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager?.register { [weak self] digit in
            self?.statusBarController?.applyProfileByShortcutIndex(digit)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
    }
}
