import XCTest
@testable import StoreCore

/// AuthService + FakeAuthAPI: sign in, sign up, lockout, restore, sign out.
final class AuthServiceTests: XCTestCase {

    private func makeService(store: InMemorySessionStore = InMemorySessionStore(),
                             now: @escaping @Sendable () -> Date = Date.init) -> (AuthService, FakeAuthAPI) {
        let api = FakeAuthAPI(latency: 0)
        return (AuthService(api: api, store: store, now: now), api)
    }

    func testDemoAccountSignsInAndTheSessionIsSaved() async throws {
        let store = InMemorySessionStore()
        let (auth, _) = makeService(store: store)

        let session = try await auth.signIn(email: FakeAuthAPI.demoEmail, password: FakeAuthAPI.demoPassword)

        XCTAssertEqual(session.user.email, FakeAuthAPI.demoEmail)
        XCTAssertEqual(try store.load(), session, "the session is stored so the next launch skips sign-in")
    }

    func testWrongPasswordIsRejected() async {
        let (auth, _) = makeService()
        do {
            _ = try await auth.signIn(email: FakeAuthAPI.demoEmail, password: "nope")
            XCTFail("expected invalidCredentials")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCredentials)
        }
    }

    func testFiveWrongPasswordsLockTheAccount() async {
        let (auth, _) = makeService()
        for _ in 0..<FakeAuthAPI.maxAttempts {
            _ = try? await auth.signIn(email: FakeAuthAPI.demoEmail, password: "nope")
        }
        do {
            _ = try await auth.signIn(email: FakeAuthAPI.demoEmail, password: FakeAuthAPI.demoPassword)
            XCTFail("expected accountLocked")
        } catch {
            XCTAssertEqual(error as? AuthError, .accountLocked(minutes: 5), "even the right password is refused while locked")
        }
    }

    func testSignUpThenSignInWithTheNewAccount() async throws {
        let (auth, _) = makeService()
        let request = SignUpRequest(fullName: "Tunde Bakare", email: "tunde.bakare@nutm.edu.ng", password: "Secret-123", matricNumber: nil)

        _ = try await auth.signUp(request)
        let session = try await auth.signIn(email: "tunde.bakare@nutm.edu.ng", password: "Secret-123")

        XCTAssertEqual(session.user.fullName, "Tunde Bakare")
    }

    func testTheSameEmailCannotRegisterTwice() async {
        let (auth, _) = makeService()
        let request = SignUpRequest(fullName: "Someone", email: FakeAuthAPI.demoEmail, password: "Secret-123", matricNumber: nil)
        do {
            _ = try await auth.signUp(request)
            XCTFail("expected emailAlreadyInUse")
        } catch {
            XCTAssertEqual(error as? AuthError, .emailAlreadyInUse)
        }
    }

    func testOfflineIsReportedAsNetwork() async {
        let (auth, api) = makeService()
        await api.setOffline(true)
        do {
            _ = try await auth.signIn(email: FakeAuthAPI.demoEmail, password: FakeAuthAPI.demoPassword)
            XCTFail("expected network")
        } catch {
            XCTAssertEqual(error as? AuthError, .network)
        }
    }

    func testRestoreReturnsAValidSessionAndDropsAnExpiredOne() async {
        let user = User(fullName: "Demo Student", email: FakeAuthAPI.demoEmail)
        let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)
        let valid = Session(token: "t", expiresAt: fixedNow.addingTimeInterval(60), user: user)
        let expired = Session(token: "t", expiresAt: fixedNow.addingTimeInterval(-60), user: user)

        let (good, _) = makeService(store: InMemorySessionStore(session: valid), now: { fixedNow })
        let restored = await good.restoreSession()
        XCTAssertEqual(restored, valid)

        let expiredStore = InMemorySessionStore(session: expired)
        let (stale, _) = makeService(store: expiredStore, now: { fixedNow })
        let nothing = await stale.restoreSession()
        XCTAssertNil(nothing)
        XCTAssertNil(try expiredStore.load(), "an expired session is deleted, not kept")
    }

    func testSignOutClearsTheStore() async throws {
        let store = InMemorySessionStore()
        let (auth, _) = makeService(store: store)
        _ = try await auth.signIn(email: FakeAuthAPI.demoEmail, password: FakeAuthAPI.demoPassword)

        await auth.signOut()

        XCTAssertNil(try store.load())
    }
}
