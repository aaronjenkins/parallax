import CoreGraphics

struct DisplayIdentifier: Codable, Hashable {
    let vendorNumber: UInt32
    let modelNumber: UInt32
    let serialNumber: UInt32
    let isBuiltin: Bool

    init(from displayID: CGDirectDisplayID) {
        self.vendorNumber = CGDisplayVendorNumber(displayID)
        self.modelNumber = CGDisplayModelNumber(displayID)
        self.serialNumber = CGDisplaySerialNumber(displayID)
        self.isBuiltin = CGDisplayIsBuiltin(displayID) != 0
    }

    init(vendorNumber: UInt32, modelNumber: UInt32, serialNumber: UInt32, isBuiltin: Bool) {
        self.vendorNumber = vendorNumber
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.isBuiltin = isBuiltin
    }
}
