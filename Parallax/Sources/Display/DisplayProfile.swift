import Foundation

struct DisplayProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var arrangements: [DisplayArrangement]
    let createdAt: Date
    var shortcutIndex: Int?

    init(name: String, arrangements: [DisplayArrangement]) {
        self.id = UUID()
        self.name = name
        self.arrangements = arrangements
        self.createdAt = Date()
        self.shortcutIndex = nil
    }

    func matches(current: [DisplayArrangement]) -> Bool {
        guard arrangements.count == current.count else { return false }
        for arrangement in arrangements {
            guard let match = current.first(where: { $0.displayID == arrangement.displayID }) else {
                return false
            }
            let positionMatch = abs(match.originX - arrangement.originX) <= 1
                && abs(match.originY - arrangement.originY) <= 1
            let resolutionMatch = match.width == arrangement.width && match.height == arrangement.height
            if !positionMatch || !resolutionMatch { return false }
        }
        return true
    }
}
