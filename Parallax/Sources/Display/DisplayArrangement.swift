import Foundation

struct DisplayArrangement: Codable {
    let displayID: DisplayIdentifier
    let originX: Int32
    let originY: Int32
    let width: Int
    let height: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let refreshRate: Double
    let isPrimary: Bool

    var displayName: String {
        if displayID.isBuiltin {
            return "Built-in Display"
        }
        return "External Display (\(width)×\(height))"
    }

    var positionDescription: String {
        return "(\(originX), \(originY))"
    }

    var resolutionDescription: String {
        return "\(width)×\(height) @ \(String(format: "%.0f", refreshRate))Hz"
    }
}
