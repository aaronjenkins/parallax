import CoreGraphics
import Foundation

final class DisplayChangeMonitor {

    fileprivate var callback: (() -> Void)?

    init(onChange: @escaping () -> Void) {
        self.callback = onChange
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }
}

private func displayReconfigurationCallback(
    _ displayID: CGDirectDisplayID,
    _ flags: CGDisplayChangeSummaryFlags,
    _ userInfo: UnsafeMutableRawPointer?
) {
    // Only act on the "complete" flag to avoid double-firing
    guard flags.contains(.beginConfigurationFlag) == false else { return }
    guard let userInfo = userInfo else { return }

    let monitor = Unmanaged<DisplayChangeMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    DispatchQueue.main.async {
        monitor.callback?()
    }
}
