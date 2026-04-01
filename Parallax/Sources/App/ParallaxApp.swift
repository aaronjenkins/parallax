import SwiftUI

@main
struct ParallaxApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — menubar only
        Settings {
            EmptyView()
        }
    }
}
