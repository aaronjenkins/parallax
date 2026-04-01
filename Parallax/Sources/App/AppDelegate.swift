import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var displayChangeMonitor: DisplayChangeMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        displayChangeMonitor = DisplayChangeMonitor { [weak self] in
            self?.statusBarController?.rebuildMenu()
        }
    }
}
