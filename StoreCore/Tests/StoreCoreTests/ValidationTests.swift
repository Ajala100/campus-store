import XCTest
@testable import StoreCore

/// The form rules on their own. These are the specification: if a rule changes, a test changes.
final class ValidationTests: XCTestCase {

    func testEmailFormat() {
        XCTAssertEqual(Validation.emailError("", requireSchoolDomain: false), "Enter your email.")
        XCTAssertEqual(Validation.emailError("adaeze", requireSchoolDomain: false), "Enter a valid email address.")
        XCTAssertEqual(Validation.emailError("a@@nutm.edu.ng", requireSchoolDomain: false), "Enter a valid email address.")
        XCTAssertEqual(Validation.emailError("@nutm.edu.ng", requireSchoolDomain: false), "Enter a valid email address.")
        XCTAssertEqual(Validation.emailError("a@nutm.", requireSchoolDomain: false), "Enter a valid email address.")
        XCTAssertNil(Validation.emailError("adaeze@gmail.com", requireSchoolDomain: false))
    }

    func testSchoolDomainOnlyWhenRequired() {
        XCTAssertEqual(Validation.emailError("adaeze@gmail.com", requireSchoolDomain: true), "Use your school email (…@nutm.edu.ng).")
        XCTAssertNil(Validation.emailError("adaeze.okonkwo@nutm.edu.ng", requireSchoolDomain: true))
    }

    func testNameRules() {
        XCTAssertEqual(Validation.nameError(""), "Enter your full name.")
        XCTAssertNotNil(Validation.nameError("A"))
        XCTAssertNil(Validation.nameError("Al"))
        XCTAssertNotNil(Validation.nameError(String(repeating: "a", count: 61)))
        XCTAssertEqual(Validation.nameError("1234"), "Your name should contain letters.")
    }

    func testMatricIsOptionalButMustMatchTheFormat() {
        XCTAssertNil(Validation.matricError(""))
        XCTAssertNil(Validation.matricError("NUTM/2026/0123"))
        XCTAssertEqual(Validation.matricError("2026/0123"), "Use the format NUTM/2026/0123.")
        XCTAssertNotNil(Validation.matricError("NUTM/26/0123"))
        XCTAssertNotNil(Validation.matricError("NUTM/2026/AB12"))
    }

    func testNormalisation() {
        XCTAssertEqual(Validation.normalizedName("  Adaeze    Okonkwo "), "Adaeze Okonkwo")
        XCTAssertEqual(Validation.normalizedEmail(" Adaeze@NUTM.edu.ng \n"), "adaeze@nutm.edu.ng")
        XCTAssertEqual(Validation.normalizedMatric(" nutm/2026/0123 "), "NUTM/2026/0123")
    }

    func testPasswords() {
        XCTAssertEqual(Validation.signInPasswordError(""), "Enter your password.")
        XCTAssertNil(Validation.signInPasswordError("x"), "sign-in never second-guesses a password: the server decides")
        XCTAssertEqual(Validation.newPasswordError("1234567"), "Password must be at least 8 characters.")
        XCTAssertNil(Validation.newPasswordError("12345678"))
        XCTAssertEqual(Validation.confirmPasswordError("abc", password: "abd"), "Passwords don’t match.")
        XCTAssertNil(Validation.confirmPasswordError("abc", password: "abc"))
    }

    func testStrengthMeter() {
        XCTAssertEqual(Validation.strength(of: ""), .empty)
        XCTAssertEqual(Validation.strength(of: "Ab1!"), .weak, "under 8 characters is always weak")
        XCTAssertEqual(Validation.strength(of: "password"), .weak)
        XCTAssertEqual(Validation.strength(of: "password1"), .fair)
        XCTAssertEqual(Validation.strength(of: "Password1"), .good)
        XCTAssertEqual(Validation.strength(of: "Password-1234"), .strong)
    }

    func testOnlyTheLengthRuleIsRequired() {
        let rules = Validation.rules(for: "Password1")
        XCTAssertEqual(rules.map(\.isMet), [true, true, true])
        XCTAssertEqual(rules.filter(\.isRequired).count, 1)
    }
}
