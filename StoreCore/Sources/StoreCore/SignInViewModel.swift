import Foundation

// MARK: - Sign in (MVVM)
//
//   SignInViewController ──(what the user types, taps)──▶ SignInViewModel ──▶ AuthService
//          ▲                                                     │
//          └──────── onChange: redraw errors / phase / info ─────┘
//
// The ViewModel owns the STATE and the RULES. The view controller owns the PIXELS.
// When `phase` becomes `.signedIn`, the screen tells the coordinator, which decides what
// comes next. Nothing here imports UIKit, so `SignInViewModelTests` runs in milliseconds.

@MainActor
public final class SignInViewModel {

    public struct FieldErrors: Equatable, Sendable {
        public var email: String?
        public var password: String?
        /// Problems that belong to no single field (wrong password, offline, locked) → a banner.
        public var form: String?
        public var isEmpty: Bool { email == nil && password == nil && form == nil }
        public init(email: String? = nil, password: String? = nil, form: String? = nil) {
            self.email = email; self.password = password; self.form = form
        }
    }

    public enum Phase: Equatable, Sendable {
        case editing
        case submitting
        case signedIn(Session)
    }

    // MARK: Inputs (the screen writes these as the user types). Editing clears that field's error.
    public var email = "" { didSet { clear(\.email) } }
    public var password = "" { didSet { clear(\.password) } }

    // MARK: Outputs (the screen draws these, and only these)
    public private(set) var errors = FieldErrors() { didSet { if errors != oldValue { onChange?() } } }
    public private(set) var phase: Phase = .editing { didSet { onChange?() } }
    /// A neutral, non-error message, e.g. after "Forgot password?".
    public private(set) var info: String? { didSet { onChange?() } }
    public var onChange: (() -> Void)?

    public var isSubmitting: Bool { phase == .submitting }

    // Copy lives here, not in the view controller, so it is testable and in one place.
    public let title = "Welcome back"
    public let subtitle = "Sign in to shop textbooks, merch and gadgets on campus."
    public let submitTitle = "Sign in"
    public let forgotTitle = "Forgot password?"
    public let signUpPrompt = "New to Campus Store?"
    public let signUpTitle = "Create an account"

    private let auth: AuthService

    public init(auth: AuthService) { self.auth = auth }

    // MARK: Intents

    public func submit() async {
        guard phase != .submitting else { return }      // a double-tap sends one request, not two
        info = nil
        let cleanEmail = Validation.normalizedEmail(email)

        // 1. Validate locally first: no point asking the server about "adaeze@".
        let local = FieldErrors(email: Validation.emailError(cleanEmail, requireSchoolDomain: false),
                                password: Validation.signInPasswordError(password))
        errors = local
        guard local.isEmpty else { return }

        // 2. Ask the server.
        phase = .submitting
        do {
            let session = try await auth.signIn(email: cleanEmail, password: password)
            phase = .signedIn(session)
        } catch let error as AuthError {
            phase = .editing
            errors = FieldErrors(form: error.userMessage)
        } catch {
            phase = .editing
            errors = FieldErrors(form: AuthError.unknown.userMessage)
        }
    }

    /// "Forgot password?": needs a valid email first, then always shows the same message,
    /// so the screen never reveals whether an account exists.
    public func forgotPassword() async {
        let cleanEmail = Validation.normalizedEmail(email)
        if let problem = Validation.emailError(cleanEmail, requireSchoolDomain: false) {
            errors = FieldErrors(email: problem == "Enter your email." ? "Enter your email, then tap “Forgot password?”." : problem)
            return
        }
        do {
            try await auth.requestPasswordReset(email: cleanEmail)
            errors = FieldErrors()
            info = "If an account exists for \(cleanEmail), we’ve sent a reset link."
        } catch let error as AuthError {
            errors = FieldErrors(form: error.userMessage)
        } catch {
            errors = FieldErrors(form: AuthError.unknown.userMessage)
        }
    }

    // MARK: Private

    private func clear(_ keyPath: WritableKeyPath<FieldErrors, String?>) {
        var next = errors
        next[keyPath: keyPath] = nil
        next.form = nil
        errors = next
    }
}
