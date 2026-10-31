import Foundation

// MARK: - The seam between the app and "the server"
//
// The app only ever talks to `AuthAPI`, a protocol. Today the implementation is
// `FakeAuthAPI` (below): an in-memory server with a realistic delay, so the demo needs no
// backend. Tomorrow a `RemoteAuthAPI` that calls a real REST endpoint can replace it in ONE
// line in AppCoordinator — no ViewModel or screen changes. That is the repository /
// dependency-injection idea from class.

public protocol AuthAPI: Sendable {
    func signIn(email: String, password: String) async throws -> Session
    func signUp(_ request: SignUpRequest) async throws -> Session
    func requestPasswordReset(email: String) async throws
}

/// Every way sign-in or sign-up can fail, as the UI needs to know it — not as HTTP codes.
public enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case emailAlreadyInUse
    case accountLocked(minutes: Int)
    case network
    case unknown

    /// A message safe to show a person. Note: the same message whether the email exists
    /// or not — telling an attacker "no such account" helps them guess emails.
    public var userMessage: String {
        switch self {
        case .invalidCredentials: return "That email and password don’t match."
        case .emailAlreadyInUse: return "An account with this email already exists. Sign in instead."
        case .accountLocked(let minutes): return "Too many attempts. Try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .network: return "You’re offline. Check your connection and try again."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}

// MARK: - A fake server, good enough to demo every path

/// An in-memory "backend". It behaves like a real one in the ways the UI cares about:
/// it takes time to answer, rejects wrong passwords, refuses a taken email, locks an account
/// after 5 wrong attempts, and can pretend to be offline.
///
/// It is an `actor`, so two requests can never corrupt its dictionaries at the same time.
public actor FakeAuthAPI: AuthAPI {

    private struct Account { var user: User; var password: String }

    private var accounts: [String: Account] = [:]          // keyed by lower-cased email
    private var failedAttempts: [String: Int] = [:]
    private let latencyNanoseconds: UInt64
    public private(set) var isOffline = false
    public private(set) var resetRequests: [String] = []    // so tests can check it was called

    public static let maxAttempts = 5
    public static let demoEmail = "demo@nutm.edu.ng"
    public static let demoPassword = "Password1"

    /// `latency` lets the app feel real (≈0.8 s) while tests run instantly (0).
    public init(latency: TimeInterval = 0.8, seedDemoAccount: Bool = true) {
        self.latencyNanoseconds = UInt64(max(0, latency) * 1_000_000_000)
        if seedDemoAccount {
            let demo = User(fullName: "Demo Student", email: Self.demoEmail, matricNumber: "NUTM/2026/0001")
            accounts[Self.demoEmail] = Account(user: demo, password: Self.demoPassword)
        }
    }

    public func setOffline(_ offline: Bool) { isOffline = offline }

    public func signIn(email: String, password: String) async throws -> Session {
        try await pretendToTravel()
        let key = email.lowercased()
        if failedAttempts[key, default: 0] >= Self.maxAttempts {
            throw AuthError.accountLocked(minutes: 5)
        }
        guard let account = accounts[key], account.password == password else {
            failedAttempts[key, default: 0] += 1
            throw AuthError.invalidCredentials
        }
        failedAttempts[key] = 0
        return makeSession(for: account.user)
    }

    public func signUp(_ request: SignUpRequest) async throws -> Session {
        try await pretendToTravel()
        let key = request.email.lowercased()
        guard accounts[key] == nil else { throw AuthError.emailAlreadyInUse }
        let user = User(fullName: request.fullName, email: key, matricNumber: request.matricNumber)
        accounts[key] = Account(user: user, password: request.password)
        return makeSession(for: user)
    }

    public func requestPasswordReset(email: String) async throws {
        try await pretendToTravel()
        resetRequests.append(email.lowercased())   // a real server would send an email
    }

    // MARK: Private

    private func pretendToTravel() async throws {
        if latencyNanoseconds > 0 { try await Task.sleep(nanoseconds: latencyNanoseconds) }
        if isOffline { throw AuthError.network }
    }

    private func makeSession(for user: User) -> Session {
        Session(token: "cs_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
                expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60),   // a week
                user: user)
    }
}
