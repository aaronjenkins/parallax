import CoreGraphics

enum DisplayApplyError: Error, CustomStringConvertible {
    case displayNotFound(DisplayIdentifier)
    case modeNotFound(width: Int, height: Int, refreshRate: Double)
    case configurationFailed(CGError)

    var description: String {
        switch self {
        case .displayNotFound(let id):
            return "Display not found (vendor: \(id.vendorNumber), model: \(id.modelNumber))"
        case .modeNotFound(let w, let h, let r):
            return "Display mode \(w)×\(h)@\(String(format: "%.0f", r))Hz not available"
        case .configurationFailed(let err):
            return "Configuration failed with error code \(err.rawValue)"
        }
    }
}

final class DisplayManager {

    static let shared = DisplayManager()

    private init() {}

    // MARK: - Read

    func currentDisplays() -> [DisplayArrangement] {
        let displayIDs = activeDisplayIDs()
        return displayIDs.compactMap { arrangement(for: $0) }
    }

    func resolveDisplayID(for identifier: DisplayIdentifier) -> CGDirectDisplayID? {
        activeDisplayIDs().first { id in
            CGDisplayVendorNumber(id) == identifier.vendorNumber
                && CGDisplayModelNumber(id) == identifier.modelNumber
                && CGDisplaySerialNumber(id) == identifier.serialNumber
        }
    }

    // MARK: - Apply

    func apply(profile: DisplayProfile) -> [DisplayApplyError] {
        var errors: [DisplayApplyError] = []
        var config: CGDisplayConfigRef?

        let beginErr = CGBeginDisplayConfiguration(&config)
        guard beginErr == .success, let config = config else {
            return [.configurationFailed(beginErr)]
        }

        // Apply primary display first (origin 0,0), then secondaries
        let sorted = profile.arrangements.sorted { $0.isPrimary && !$1.isPrimary }

        for arrangement in sorted {
            guard let cgID = resolveDisplayID(for: arrangement.displayID) else {
                errors.append(.displayNotFound(arrangement.displayID))
                continue
            }

            // Set position
            CGConfigureDisplayOrigin(config, cgID, arrangement.originX, arrangement.originY)

            // Set display mode
            if let mode = findMatchingMode(
                for: cgID,
                width: arrangement.width,
                height: arrangement.height,
                pixelWidth: arrangement.pixelWidth,
                pixelHeight: arrangement.pixelHeight,
                refreshRate: arrangement.refreshRate
            ) {
                CGConfigureDisplayWithDisplayMode(config, cgID, mode, nil)
            } else {
                errors.append(.modeNotFound(
                    width: arrangement.width,
                    height: arrangement.height,
                    refreshRate: arrangement.refreshRate
                ))
            }
        }

        let completeErr = CGCompleteDisplayConfiguration(config, .permanently)
        if completeErr != .success {
            errors.append(.configurationFailed(completeErr))
        }

        return errors
    }

    // MARK: - Private

    private func activeDisplayIDs() -> [CGDirectDisplayID] {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return []
        }
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount) == .success else {
            return []
        }
        return displayIDs
    }

    private func arrangement(for displayID: CGDirectDisplayID) -> DisplayArrangement? {
        guard let mode = CGDisplayCopyDisplayMode(displayID) else { return nil }

        let bounds = CGDisplayBounds(displayID)
        let identifier = DisplayIdentifier(from: displayID)

        return DisplayArrangement(
            displayID: identifier,
            originX: Int32(bounds.origin.x),
            originY: Int32(bounds.origin.y),
            width: mode.width,
            height: mode.height,
            pixelWidth: mode.pixelWidth,
            pixelHeight: mode.pixelHeight,
            refreshRate: mode.refreshRate,
            isPrimary: CGDisplayIsMain(displayID) != 0
        )
    }

    private func findMatchingMode(
        for displayID: CGDirectDisplayID,
        width: Int,
        height: Int,
        pixelWidth: Int,
        pixelHeight: Int,
        refreshRate: Double
    ) -> CGDisplayMode? {
        let options: CFDictionary = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
        guard let allModes = CGDisplayCopyAllDisplayModes(displayID, options) as? [CGDisplayMode] else {
            return nil
        }

        // Exact match first: points, pixels, and refresh rate
        if let exact = allModes.first(where: {
            $0.width == width && $0.height == height
                && $0.pixelWidth == pixelWidth && $0.pixelHeight == pixelHeight
                && abs($0.refreshRate - refreshRate) < 1.0
        }) {
            return exact
        }

        // Fallback: match points and prefer highest pixel density
        let pointMatches = allModes.filter { $0.width == width && $0.height == height }
        return pointMatches.max(by: { $0.pixelWidth < $1.pixelWidth })
    }
}
