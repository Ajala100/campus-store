import XCTest
@testable import StoreCore

/// The two ViewModels, driven exactly as the screens drive them — without any screen.
@MainActor
final class SignInViewModelTests: XCTestCase {

    private func makeViewModel() -> (SignInViewModel, FakeAuthAPI) {
        let api = FakeAuthAPI(latency: 0)
        return (SignInViewModel(auth: AuthService(api: api, store: InMemorySessionStore())), api)
    }

    func testEmptyFormShowsBothErrorsAndCallsNoServer() async {
        let (vm, _) = makeViewModel()
        await vm.submit()
        XCTAssertEqual(vm.errors.email, "Enter your email.")
        XCTAssertEqual(vm.errors.password, "Enter your password.")
        XCTAssertEqual(vm.phase, .editing)
    }

    func testDemoAccountSignsIn() async {
        let (vm, _) = makeViewModel()
        vm.email = "  DEMO@nutm.edu.ng "          // messy input is normalised
        vm.password = FakeAuthAPI.demoPassword

        await vm.submit()

        guard case .signedIn(let session) = vm.phase else { return XCTFail("expected signedIn, got \(vm.phase)") }
        XCTAssertEqual(session.user.email, FakeAuthAPI.demoEmail)
    }

    func testWrongPasswordIsABannerNotAFieldError() async {
        let (vm, _) = makeViewModel()
        vm.email = FakeAuthAPI.demoEmail
        vm.password = "wrong"

        await vm.submit()

        XCTAssertEqual(vm.errors.form, AuthError.invalidCredentials.userMessage)
        XCTAssertNil(vm.errors.email, "never say which of the two was wrong")
        XCTAssertNil(vm.errors.password)
    }

    func testTypingClearsTheError() async {
        let (vm, _) = makeViewModel()
        await vm.submit()
        XCTAssertNotNil(vm.errors.email)

        vm.email = "d"

        XCTAssertNil(vm.errors.email)
        XCTAssertNotNil(vm.errors.password, "only the edited field is cleared")
    }

    func testForgotPasswordNeedsAnEmailThenShowsANeutralMessage() async {
        let (vm, api) = makeViewModel()
        await vm.forgotPassword()
        XCTAssertNotNil(vm.errors.email)

        vm.email = "Someone@nutm.edu.ng"
        await vm.forgotPassword()

        XCTAssertEqual(vm.info, "If an account exists for someone@nutm.edu.ng, we’ve sent a reset link.")
        let requests = await api.resetRequests
        XCTAssertEqual(requests, ["someone@nutm.edu.ng"])
    }

    func testEveryChangeIsReportedToTheView() async {
        let (vm, _) = makeViewModel()
        var calls = 0
        vm.onChange = { calls += 1 }
        vm.email = FakeAuthAPI.demoEmail
        vm.password = FakeAuthAPI.demoPassword

        await vm.submit()

        XCTAssertGreaterThanOrEqual(calls, 2, "submitting, then signedIn")
    }
}

@MainActor
final class SignUpViewModelTests: XCTestCase {

    private func makeViewModel() -> SignUpViewModel {
        SignUpViewModel(auth: AuthService(api: FakeAuthAPI(latency: 0), store: InMemorySessionStore()))
    }

    private func fillValid(_ vm: SignUpViewModel) {
        vm.name = "Adaeze Okonkwo"
        vm.email = "adaeze.okonkwo@nutm.edu.ng"
        vm.password = "Correct-Horse-9"
        vm.confirmPassword = "Correct-Horse-9"
        vm.acceptedTerms = true
    }

    func testEmptyFormReportsEveryRequiredField() async {
        let vm = makeViewModel()
        await vm.submit()
        XCTAssertNotNil(vm.errors.name)
        XCTAssertNotNil(vm.errors.email)
        XCTAssertNil(vm.errors.matric, "matric number is optional")
        XCTAssertNotNil(vm.errors.password)
        XCTAssertNotNil(vm.errors.confirmPassword)
        XCTAssertNotNil(vm.errors.terms)
        XCTAssertEqual(vm.errors.firstInvalidField, .name)
        XCTAssertEqual(vm.phase, .editing)
    }

    func testValidFormCreatesTheAccount() async {
        let vm = makeViewModel()
        fillValid(vm)
        vm.matric = "nutm/2026/0123"

        await vm.submit()

        guard case .signedUp(let session) = vm.phase else { return XCTFail("expected signedUp, got \(vm.phase)") }
        XCTAssertEqual(session.user.fullName, "Adaeze Okonkwo")
        XCTAssertEqual(session.user.matricNumber, "NUTM/2026/0123")
    }

    func testNonSchoolEmailIsRefused() async {
        let vm = makeViewModel()
        fillValid(vm)
        vm.email = "adaeze@gmail.com"

        await vm.submit()

        XCTAssertEqual(vm.errors.email, "Use your school email (…@nutm.edu.ng).")
        XCTAssertEqual(vm.errors.firstInvalidField, .email)
    }

    func testMismatchedPasswordsAreCaught() async {
        let vm = makeViewModel()
        fillValid(vm)
        vm.confirmPassword = "something-else"

        await vm.submit()

        XCTAssertEqual(vm.errors.confirmPassword, "Passwords don’t match.")
        XCTAssertFalse(vm.passwordsMatch)
    }

    func testTakenEmailGoesUnderTheEmailField() async {
        let vm = makeViewModel()
        fillValid(vm)
        vm.email = FakeAuthAPI.demoEmail

        await vm.submit()

        XCTAssertEqual(vm.errors.email, AuthError.emailAlreadyInUse.userMessage)
        XCTAssertNil(vm.errors.form)
    }

    func testPasswordTypingRedrawsTheMeter() {
        let vm = makeViewModel()
        var calls = 0
        vm.onChange = { calls += 1 }

        vm.password = "P"; vm.password = "Pa"; vm.password = "Pass"

        XCTAssertEqual(calls, 3)
        XCTAssertEqual(vm.passwordStrength, .weak)
    }
}
