import Foundation

// MARK: - Sign up (MVVM)
//
// Same shape as SignInViewModel, with more to check:
//   • full name (2–60 characters, collapsed spaces)
//   • school email (…@nutm.edu.ng — only students can register)
//   • matric number (optional, NUTM/2026/0123 format if given)
//   • password with a live strength meter and checklist, typed twice
//   • terms accepted
// Everything is validated BEFORE the server is called; the server's answer (e.g. "email
// taken") is then put under the field it concerns.

@MainActor
public final class SignUpViewModel {

    public enum Field: Hashable, Sendable { case name, email, matric, password, confirmPassword, terms }

    public struct FieldErrors: Equatable, Sendable {
        public var name: String?
        public var email: String?
        public var matric: String?
        public var password: String?
        public var confirmPassword: String?
        public var terms: String?
        public var form: String?

        public init(name: String? = nil, email: String? = nil, matric: String? = nil, password: String? = nil,
                    confirmPassword: String? = nil, terms: String? = nil, form: String? = nil) {
            self.name = name; self.email = email; self.matric = matric; self.password = password
            self.confirmPassword = confirmPassword; self.terms = terms; self.form = form
        }

        public var isEmpty: Bool {
            name == nil && email == nil && matric == nil && password == nil
                && confirmPassword == nil && terms == nil && form == nil
        }

        /// Top-to-bottom: the screen scrolls to and focuses the first problem.
        public var firstInvalidField: Field? {
            if name != nil { return .name }
            if email != nil { return .email }
            if matric != nil { return .matric }
            if password != nil { return .password }
            if confirmPassword != nil { return .confirmPassword }
            if terms != nil { return .terms }
            return nil
        }
    }

    public enum Phase: Equatable, Sendable {
        case editing
        case submitting
        case signedUp(Session)
    }

    // MARK: Inputs
    public var name = "" { didSet { clear(\.name) } }
    public var email = "" { didSet { clear(\.email) } }
    public var matric = "" { didSet { clear(\.matric) } }
    public var password = "" { didSet { clear(\.password); onChange?() } }               // meter follows typing
    public var confirmPassword = "" { didSet { clear(\.confirmPassword); onChange?() } } // match tick follows typing
    public var acceptedTerms = false { didSet { clear(\.terms); onChange?() } }

    // MARK: Outputs
    public private(set) var errors = FieldErrors() { didSet { if errors != oldValue { onChange?() } } }
    public private(set) var phase: Phase = .editing { didSet { onChange?() } }
    public var onChange: (() -> Void)?

    public var isSubmitting: Bool { phase == .submitting }
    public var passwordStrength: Validation.Strength { Validation.strength(of: password) }
    public var passwordRules: [Validation.PasswordRule] { Validation.rules(for: password) }
    public var passwordsMatch: Bool { !confirmPassword.isEmpty && password == confirmPassword }

    public let title = "Create your account"
    public let subtitle = "Students only — sign up with your school email to start shopping."
    public let submitTitle = "Create account"
    public let termsText = "I agree to the Terms of Service and Privacy Policy"
    public let signInPrompt = "Already have an account?"
    public let signInTitle = "Sign in"

    private let auth: AuthService

    public init(auth: AuthService) { self.auth = auth }

    // MARK: Intents

    public func submit() async {
        guard phase != .submitting else { return }

        let cleanName = Validation.normalizedName(name)
        let cleanEmail = Validation.normalizedEmail(email)
        let cleanMatric = Validation.normalizedMatric(matric)

        let local = Self.validate(name: cleanName, email: cleanEmail, matric: cleanMatric, password: password,
                                  confirmPassword: confirmPassword, acceptedTerms: acceptedTerms)
        errors = local
        guard local.isEmpty else { return }       // validation is a gate: no request until it passes

        phase = .submitting
        do {
            let request = SignUpRequest(fullName: cleanName, email: cleanEmail, password: password,
                                        matricNumber: cleanMatric.isEmpty ? nil : cleanMatric)
            let session = try await auth.signUp(request)
            phase = .signedUp(session)
        } catch let error as AuthError {
            phase = .editing
            errors = Self.errors(for: error)
        } catch {
            phase = .editing
            errors = FieldErrors(form: AuthError.unknown.userMessage)
        }
    }

    // MARK: Rules (static and pure, tested directly)

    nonisolated public static func validate(name: String, email: String, matric: String, password: String,
                                            confirmPassword: String, acceptedTerms: Bool) -> FieldErrors {
        FieldErrors(
            name: Validation.nameError(name),
            email: Validation.emailError(email, requireSchoolDomain: true),
            matric: Validation.matricError(matric),
            password: Validation.newPasswordError(password),
            confirmPassword: Validation.confirmPasswordError(confirmPassword, password: password),
            terms: acceptedTerms ? nil : "Please accept the terms to continue.")
    }

    /// The server's answer goes next to the field it concerns; the rest becomes a banner.
    nonisolated static func errors(for error: AuthError) -> FieldErrors {
        switch error {
        case .emailAlreadyInUse: return FieldErrors(email: error.userMessage)
        default:                 return FieldErrors(form: error.userMessage)
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
