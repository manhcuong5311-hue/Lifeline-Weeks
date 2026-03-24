import Foundation

struct PersistenceService {

    // MARK: - Storage key

    private static let profileKey = "life.userProfile"

    // MARK: - Encoder / Decoder (reused, never recreated)

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Public API

    /// Persist a `UserProfile`. Returns `false` if encoding fails.
    @discardableResult
    static func save(_ profile: UserProfile) -> Bool {
        guard let data = try? encoder.encode(profile) else {
            assertionFailure("PersistenceService: failed to encode UserProfile")
            return false
        }
        UserDefaults.standard.set(data, forKey: profileKey)
        return true
    }

    /// Load a previously saved `UserProfile`.
    /// Returns `nil` on missing data, corrupt data, or invalid values — never throws or crashes.
    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            return nil               // first launch — no data yet
        }
        guard let profile = try? decoder.decode(UserProfile.self, from: data) else {
            // Data exists but couldn't be decoded (schema change, corruption, etc.)
            // Remove it so the app doesn't loop trying to read it.
            UserDefaults.standard.removeObject(forKey: profileKey)
            return nil
        }
        return profile.sanitised()  // clamp values before handing to the ViewModel
    }

    /// Wipe stored profile (e.g. reset / re-onboard).
    static func clear() {
        UserDefaults.standard.removeObject(forKey: profileKey)
    }
}
