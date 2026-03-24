import Foundation

struct UserProfile: Codable, Equatable {
    var birthDate: Date
    var lifeExpectancy: Int
    var name: String

    init(birthDate: Date, lifeExpectancy: Int, name: String = "") {
        self.birthDate      = birthDate
        self.lifeExpectancy = lifeExpectancy
        self.name           = name
    }

    // Custom decoder so old saved profiles without `name` still load correctly
    init(from decoder: Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        birthDate       = try c.decode(Date.self, forKey: .birthDate)
        lifeExpectancy  = try c.decode(Int.self,  forKey: .lifeExpectancy)
        name            = (try? c.decode(String.self, forKey: .name)) ?? ""
    }

    enum CodingKeys: String, CodingKey { case birthDate, lifeExpectancy, name }

    // MARK: - Boundaries

    static let minBirthYear   = 1900
    static let maxLifeExpect  = 120
    static let minLifeExpect  = 40

    static var earliestBirth: Date {
        Calendar.current.date(from: DateComponents(year: minBirthYear, month: 1, day: 1)) ?? .distantPast
    }

    // MARK: - Validation

    /// Returns a sanitised copy — safe against all edge cases, never crashes.
    func sanitised() -> UserProfile {
        // Life expectancy: 40…120 years
        let expectancy = max(UserProfile.minLifeExpect, min(UserProfile.maxLifeExpect, lifeExpectancy))

        // Birth date: 1900-01-01 … today (future or implausible dates rejected)
        let today  = Calendar.current.startOfDay(for: Date())
        let oldest = UserProfile.earliestBirth
        let birth  = min(max(birthDate, oldest), today)

        // Guard: user can't be older than max life expectancy
        let maxAge  = UserProfile.maxLifeExpect
        let minBirth = Calendar.current.date(byAdding: .year, value: -maxAge, to: today) ?? oldest
        let finalBirth = max(birth, minBirth)

        return UserProfile(birthDate: finalBirth, lifeExpectancy: expectancy, name: name)
    }

    /// True when the profile represents a plausible human lifespan.
    var isValid: Bool {
        let s = sanitised()
        return s.birthDate == birthDate && s.lifeExpectancy == lifeExpectancy
    }
}
