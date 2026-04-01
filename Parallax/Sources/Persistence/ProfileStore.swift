import Foundation

final class ProfileStore {

    static let shared = ProfileStore()

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Parallax", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("profiles.json")
    }

    func load() -> [DisplayProfile] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([DisplayProfile].self, from: data)) ?? []
    }

    func save(_ profiles: [DisplayProfile]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(profiles) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func add(_ profile: DisplayProfile) {
        var profiles = load()
        profiles.append(profile)
        save(profiles)
    }

    func delete(id: UUID) {
        var profiles = load()
        profiles.removeAll { $0.id == id }
        save(profiles)
    }

    func rename(id: UUID, to newName: String) {
        var profiles = load()
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles[index].name = newName
            save(profiles)
        }
    }

    func updateShortcutIndex(id: UUID, index: Int?) {
        var profiles = load()
        if let i = profiles.firstIndex(where: { $0.id == id }) {
            profiles[i].shortcutIndex = index
            // Clear the index from any other profile that had it
            if let index = index {
                for j in profiles.indices where j != i {
                    if profiles[j].shortcutIndex == index {
                        profiles[j].shortcutIndex = nil
                    }
                }
            }
            save(profiles)
        }
    }
}
