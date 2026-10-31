import Foundation

// MARK: - Where the session lives

/// Saving, loading and clearing the session. The app uses `KeychainSessionStore`
/// (encrypted, in the app target); tests use `InMemorySessionStore`.
public protocol SessionStoring: Sendable {
    func load() throws -> Session?
    func save(_ session: Session) throws
    func clear() throws
}

public final class InMemorySessionStore: SessionStoring, @unchecked Sendable {
    private var session: Session?
    private let lock = NSLock()
    public init(session: Session? = nil) { self.session = session }
    public func load() throws -> Session? { lock.lock(); defer { lock.unlock() }; return session }
    public func save(_ session: Session) throws { lock.lock(); defer { lock.unlock() }; self.session = session }
    public func clear() throws { lock.lock(); defer { lock.unlock() }; session = nil }
}

// MARK: - The whole auth story in one object
//
//   Sign in screen  ──▶ AuthService.signIn   ──▶ api.signIn   → Session ──▶ store.save (Keychain)
//   Sign up screen  ──▶ AuthService.signUp   ──▶ api.signUp   → Session ──▶ store.save
//   App launch      ──▶ AuthService.restoreSession  ← Keychain (skip Sign in if still valid)
//   Home            ──▶ AuthService.signOut  ──▶ store.clear
//
// The password goes to the server once and is never stored on the phone.
// An actor: a sign-out can never interleave with a sign-in half-way through.

public actor AuthService {
    private let api: any AuthAPI
    private let store: any SessionStoring
    private let now: @Sendable () -> Date

    public init(api: any AuthAPI, store: any SessionStoring, now: @escaping @Sendable () -> Date = Date.init) {
        self.api = api; self.store = store; self.now = now
    }

    @discardableResult
    public func signIn(email: String, password: String) async throws -> Session {
        let session = try await api.signIn(email: email, password: password)
        try store.save(session)
        return session
    }

    @discardableResult
    public func signUp(_ request: SignUpRequest) async throws -> Session {
        let session = try await api.signUp(request)
        try store.save(session)
        return session
    }

    public func requestPasswordReset(email: String) async throws {
        try await api.requestPasswordReset(email: email)
    }

    /// The saved session if it is still valid; an expired one is deleted, not used.
    public func restoreSession() -> Session? {
        guard let session = try? store.load() else { return nil }
        guard session.expiresAt > now() else {
            try? store.clear()
            return nil
        }
        return session
    }

    public func signOut() {
        try? store.clear()
    }
}
