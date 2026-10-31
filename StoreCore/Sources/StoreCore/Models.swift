import Foundation

// MARK: - Domain models
//
// Value types (structs), `Codable` so a Session can be saved to the Keychain as JSON,
// `Sendable` so they can cross between actors (AuthService is an actor) safely.

/// A signed-in student.
public struct User: Codable, Hashable, Sendable {
    public let id: UUID
    public let fullName: String
    public let email: String
    public let matricNumber: String?

    public init(id: UUID = UUID(), fullName: String, email: String, matricNumber: String? = nil) {
        self.id = id; self.fullName = fullName; self.email = email; self.matricNumber = matricNumber
    }

    /// "Adaeze Okonkwo" → "Adaeze" — for "Welcome back, Adaeze".
    public var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
}

/// What the server hands back after a successful sign-in or sign-up:
/// an opaque token (never the password) and who it belongs to.
public struct Session: Codable, Hashable, Sendable {
    public let token: String
    public let expiresAt: Date
    public let user: User

    public init(token: String, expiresAt: Date, user: User) {
        self.token = token; self.expiresAt = expiresAt; self.user = user
    }
}

/// The body of a sign-up request, already validated and normalised by the ViewModel.
public struct SignUpRequest: Equatable, Sendable {
    public let fullName: String
    public let email: String
    public let password: String
    public let matricNumber: String?

    public init(fullName: String, email: String, password: String, matricNumber: String?) {
        self.fullName = fullName; self.email = email; self.password = password; self.matricNumber = matricNumber
    }
}

/// A product in the store — only used to give Home something real to show after sign-in.
public struct Product: Hashable, Sendable {
    public let name: String
    public let priceKobo: Int
    public let symbol: String          // an SF Symbol name, so the demo needs no image assets

    public init(name: String, priceKobo: Int, symbol: String) {
        self.name = name; self.priceKobo = priceKobo; self.symbol = symbol
    }

    /// Money is stored in kobo (an Int) and only formatted at the edge: "₦4,500".
    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let naira = formatter.string(from: NSNumber(value: priceKobo / 100)) ?? "\(priceKobo / 100)"
        return "₦\(naira)"
    }

    public static let samples: [Product] = [
        Product(name: "NUTM Hoodie", priceKobo: 1_500_000, symbol: "tshirt"),
        Product(name: "Lab Notebook (A4)", priceKobo: 250_000, symbol: "book.closed"),
        Product(name: "Scientific Calculator", priceKobo: 1_200_000, symbol: "function"),
        Product(name: "USB-C Charger", priceKobo: 900_000, symbol: "bolt"),
        Product(name: "Campus Water Bottle", priceKobo: 450_000, symbol: "drop"),
    ]
}
