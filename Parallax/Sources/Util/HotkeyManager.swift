import AppKit
import Carbon.HIToolbox

final class HotkeyManager {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handler: ((Int) -> Void)?

    /// Registers Control+Option+[1-9] as global hotkeys.
    /// The handler receives the digit (1-9) when triggered.
    func register(handler: @escaping (Int) -> Void) {
        self.handler = handler

        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            NSLog("Parallax: Failed to create event tap. Accessibility permission may be required.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func unregister() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        handler = nil
    }

    var isRegistered: Bool {
        eventTap != nil
    }

    private func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let isControlOption = flags.contains(.maskControl) && flags.contains(.maskAlternate)
            && !flags.contains(.maskCommand) && !flags.contains(.maskShift)

        guard isControlOption else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Key codes for 1-9 on US keyboard
        let digitKeyCodes: [Int64: Int] = [
            18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9
        ]

        guard let digit = digitKeyCodes[keyCode] else {
            return Unmanaged.passRetained(event)
        }

        DispatchQueue.main.async { [weak self] in
            self?.handler?(digit)
        }

        // Consume the event
        return nil
    }

    deinit {
        unregister()
    }
}
