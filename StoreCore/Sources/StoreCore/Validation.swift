import Foundation

// MARK: - The form rules, in one place
//
// Pure functions: input in, error message (or nil) out. No state, no UI — so they are
// trivially unit-tested, and both ViewModels share them (DRY: one rule, one definition).

public enum Validation {

    /// Only students can create an account, so sign-up requires the school's domain.
    public static let schoolDomain = "nutm.edu.ng"
    public static let nameLength = 2...60
    public static let passwordLength = 8...128

    // MARK: Normalisation — turn what was typed into what was meant

    /// "  Adaeze    Okonkwo " → "Adaeze Okonkwo"
    public static func normalizedName(_ raw: String) -> String {
        raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// " Adaeze@NUTM.edu.ng " → "adaeze@nutm.edu.ng"
    public static func normalizedEmail(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// " nutm/2026/0123 " → "NUTM/2026/0123"
    public static func normalizedMatric(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    // MARK: Field rules — each returns nil when the value is fine

    public static func emailError(_ email: String, requireSchoolDomain: Bool) -> String? {
        if email.isEmpty { return requireSchoolDomain ? "Enter your school email." : "Enter your email." }
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        let looksValid = parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
            && !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".") && !email.contains(" ")
        guard looksValid else { return "Enter a valid email address." }
        if requireSchoolDomain && !email.hasSuffix("@" + schoolDomain) {
            return "Use your school email (…@\(schoolDomain))."
        }
        return nil
    }

    public static func nameError(_ name: String) -> String? {
        if name.isEmpty { return "Enter your full name." }
        if name.count < nameLength.lowerBound { return "Your name must be at least \(nameLength.lowerBound) characters." }
        if name.count > nameLength.upperBound { return "Your name must be \(nameLength.upperBound) characters or fewer." }
        if !name.contains(where: \.isLetter) { return "Your name should contain letters." }
        return nil
    }

    /// Optional field: empty is fine; if given, it must look like "NUTM/2026/0123".
    public static func matricError(_ matric: String) -> String? {
        guard !matric.isEmpty else { return nil }
        let parts = matric.split(separator: "/", omittingEmptySubsequences: false)
        let ok = parts.count == 3
            && parts[0].count >= 2 && parts[0].allSatisfy(\.isLetter)
            && parts[1].count == 4 && parts[1].allSatisfy(\.isNumber)
            && (3...6).contains(parts[2].count) && parts[2].allSatisfy(\.isNumber)
        return ok ? nil : "Use the format NUTM/2026/0123."
    }

    /// Sign-in only checks the password was typed: the server decides if it is right.
    public static func signInPasswordError(_ password: String) -> String? {
        password.isEmpty ? "Enter your password." : nil
    }

    /// Sign-up enforces the length; strength is advice (see `strength`).
    public static func newPasswordError(_ password: String) -> String? {
        if password.isEmpty { return "Create a password." }
        if password.count < passwordLength.lowerBound { return "Password must be at least \(passwordLength.lowerBound) characters." }
        if password.count > passwordLength.upperBound { return "Password must be \(passwordLength.upperBound) characters or fewer." }
        return nil
    }

    public static func confirmPasswordError(_ confirm: String, password: String) -> String? {
        if confirm.isEmpty { return "Type your password again." }
        return confirm == password ? nil : "Passwords don’t match."
    }

    // MARK: Password strength — advisory, drives the meter and checklist

    public struct PasswordRule: Equatable, Sendable {
        public let title: String
        public let isMet: Bool
        public let isRequired: Bool
    }

    public enum Strength: Int, Comparable, Sendable {
        case empty = 0, weak, fair, good, strong
        public static func < (l: Self, r: Self) -> Bool { l.rawValue < r.rawValue }
        public var label: String {
            switch self {
            case .empty: return ""
            case .weak: return "Weak"
            case .fair: return "Fair"
            case .good: return "Good"
            case .strong: return "Strong"
            }
        }
    }

    public static func rules(for password: String) -> [PasswordRule] {
        let mixedCase = password.contains(where: \.isLowercase) && password.contains(where: \.isUppercase)
        let numberOrSymbol = password.contains { $0.isNumber || (!$0.isLetter && !$0.isWhitespace) }
        return [
            PasswordRule(title: "At least \(passwordLength.lowerBound) characters", isMet: password.count >= passwordLength.lowerBound, isRequired: true),
            PasswordRule(title: "Upper- and lower-case letters", isMet: mixedCase, isRequired: false),
            PasswordRule(title: "A number or a symbol", isMet: numberOrSymbol, isRequired: false),
        ]
    }

    /// One point each for: 8+ characters, mixed case, a number or symbol, 12+ characters.
    public static func strength(of password: String) -> Strength {
        guard !password.isEmpty else { return .empty }
        guard password.count >= passwordLength.lowerBound else { return .weak }
        var score = rules(for: password).filter(\.isMet).count   // 1...3
        if password.count >= 12 { score += 1 }                    // 1...4
        return Strength(rawValue: score) ?? .strong
    }
}
