import UIKit
import StoreCore

/// The coordinator (the "C" in MVVM-C) owns navigation and wiring.
///
///   App launch ─▶ start() ─▶ saved session in Keychain? ──yes──▶ Home
///                                                     └─no───▶ Sign in ⇄ Sign up
///   Sign in / Sign up succeed ─▶ didAuthenticate(session) ─▶ Home
///   Home ▸ Sign out ─▶ signOut() ─▶ Sign in
///
/// Screens never push or present each other; they tell the coordinator what happened and
/// it decides what comes next. That keeps each screen reusable and testable on its own.
@MainActor
final class AppCoordinator {

    private let window: UIWindow
    private let auth: AuthService

    /// The one place the app's dependencies are chosen. To use a real backend later,
    /// swap `FakeAuthAPI()` for a `RemoteAuthAPI(baseURL:)` here — nothing else changes.
    init(window: UIWindow) {
        self.window = window
        self.auth = AuthService(api: FakeAuthAPI(), store: KeychainSessionStore())
    }

    func start() {
        Task {
            if let session = await auth.restoreSession() {
                showHome(user: session.user, animated: false)     // still signed in from last time
            } else {
                showSignIn(animated: false)
            }
            window.makeKeyAndVisible()
        }
    }

    // MARK: Auth flow

    private func showSignIn(animated: Bool) {
        let nav = UINavigationController(rootViewController: makeSignIn())
        setRoot(nav, animated: animated)
    }

    /// "New to Campus Store? Create an account" → Sign up, pushed (so "‹ Back" returns).
    func showSignUp(from nav: UINavigationController?) {
        guard let nav else { return }
        // If Sign up is already below us in the stack, go back to it instead of stacking another.
        if let existing = nav.viewControllers.first(where: { $0 is SignUpViewController }) {
            nav.popToViewController(existing, animated: true)
        } else {
            nav.pushViewController(makeSignUp(), animated: true)
        }
    }

    /// "Already have an account? Sign in" on Sign up → back to the Sign in screen.
    func showSignIn(from nav: UINavigationController?) {
        guard let nav else { return }
        if let existing = nav.viewControllers.first(where: { $0 is SignInViewController }) {
            nav.popToViewController(existing, animated: true)
        } else {
            nav.pushViewController(makeSignIn(), animated: true)
        }
    }

    /// Both screens call this on success. The session is already in the Keychain (AuthService did it).
    func didAuthenticate(_ session: Session) {
        showHome(user: session.user, animated: true)
    }

    // MARK: Signed in

    private func showHome(user: User, animated: Bool) {
        let home = HomeViewController(user: user)
        home.coordinator = self
        setRoot(UINavigationController(rootViewController: home), animated: animated)
    }

    func signOut() {
        Task {
            await auth.signOut()
            showSignIn(animated: true)
        }
    }

    // MARK: Factories — the only place screens and ViewModels are created

    private func makeSignIn() -> SignInViewController {
        let screen = SignInViewController(viewModel: SignInViewModel(auth: auth))
        screen.coordinator = self
        return screen
    }

    private func makeSignUp() -> SignUpViewController {
        let screen = SignUpViewController(viewModel: SignUpViewModel(auth: auth))
        screen.coordinator = self
        return screen
    }

    private func setRoot(_ controller: UIViewController, animated: Bool) {
        guard animated, window.rootViewController != nil else {
            window.rootViewController = controller
            return
        }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            self.window.rootViewController = controller
        }
    }
}
