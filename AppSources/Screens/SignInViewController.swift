import UIKit
import StoreCore

/// Sign in.
///
///   (bag)  Welcome back
///          Sign in to shop textbooks, merch and gadgets on campus.
///   [ ! That email and password don’t match. ]      ← banner (form-level messages)
///   Email     [                      ✉ ]
///   Password  [                      👁 ]
///                              Forgot password?
///   [              Sign in               ]
///   New to Campus Store?  Create an account
///
/// MVVM-C: this screen forwards typing to `SignInViewModel`, redraws when the ViewModel
/// says something changed (`render()`), and reports success to the coordinator. It never
/// validates, never calls the server and never creates another screen itself.
final class SignInViewController: FormScreen {

    private let viewModel: SignInViewModel
    weak var coordinator: AppCoordinator?

    private let banner = FormBannerView()
    private let emailField = StoreTextField(title: "Email", placeholder: "you@nutm.edu.ng", trailingSystemImage: "envelope")
    private let passwordField = StoreTextField(title: "Password", placeholder: "Your password")
    private let forgotButton = UIButton(type: .system)
    private lazy var submitButton = StoreButton(title: viewModel.submitTitle, style: .primary)
    private lazy var signUpLink = makeLinkButton(prompt: viewModel.signUpPrompt, action: viewModel.signUpTitle)
    private let demoHint = UILabel()

    private var wasSubmitting = false
    private var reportedSignIn = false

    init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("created in code") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonDisplayMode = .minimal

        configureFields()
        configureButtons()

        let forgotRow = UIStackView(arrangedSubviews: [UIView(), forgotButton])   // pushes the link to the right
        forgotRow.axis = .horizontal
        let form = UIStackView(arrangedSubviews: [emailField, passwordField, forgotRow])
        form.axis = .vertical
        form.spacing = StoreSpacing.control
        form.setCustomSpacing(StoreSpacing.tight, after: passwordField)

        let actions = UIStackView(arrangedSubviews: [submitButton, signUpLink, demoHint])
        actions.axis = .vertical
        actions.spacing = StoreSpacing.item

        [makeHeader(title: viewModel.title, subtitle: viewModel.subtitle), banner, form, actions]
            .forEach(content.addArrangedSubview)

        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: Setup

    private func configureFields() {
        emailField.textField.keyboardType = .emailAddress        // keyboard with @ and .
        emailField.textField.textContentType = .username         // lets iOS autofill saved logins
        emailField.textField.autocapitalizationType = .none
        emailField.textField.autocorrectionType = .no
        emailField.textField.returnKeyType = .next

        passwordField.makePasswordField(isNew: false)
        passwordField.textField.returnKeyType = .go

        emailField.textField.delegate = self
        passwordField.textField.delegate = self

        // Data flows ONE way: text field → ViewModel. The ViewModel never writes into a field.
        emailField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.viewModel.email = self.emailField.text
        }, for: .editingChanged)
        passwordField.textField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.viewModel.password = self.passwordField.text
        }, for: .editingChanged)
    }

    private func configureButtons() {
        forgotButton.setTitle(viewModel.forgotTitle, for: .normal)
        forgotButton.titleLabel?.font = StoreFont.bodyBold
        forgotButton.tintColor = StoreColor.primary
        forgotButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.view.endEditing(true)
            Task { await self.viewModel.forgotPassword() }
        }, for: .touchUpInside)

        submitButton.addAction(UIAction { [weak self] _ in self?.submitTapped() }, for: .touchUpInside)

        signUpLink.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.coordinator?.showSignUp(from: self.navigationController)
        }, for: .touchUpInside)

        demoHint.text = "Demo account: \(FakeAuthAPI.demoEmail) · \(FakeAuthAPI.demoPassword)"
        demoHint.font = StoreFont.caption
        demoHint.textColor = StoreColor.muted
        demoHint.textAlignment = .center
        demoHint.numberOfLines = 0
        demoHint.adjustsFontForContentSizeCategory = true
    }

    // MARK: Render — every pixel that can change comes from the ViewModel

    private func render() {
        let errors = viewModel.errors
        emailField.error = errors.email
        passwordField.error = errors.password
        if let form = errors.form {
            banner.show(form, kind: .error)
        } else {
            banner.show(viewModel.info, kind: .info)
        }

        submitButton.isLoading = viewModel.isSubmitting
        forgotButton.isEnabled = !viewModel.isSubmitting
        signUpLink.isEnabled = !viewModel.isSubmitting

        if case .signedIn(let session) = viewModel.phase, !reportedSignIn {
            reportedSignIn = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            coordinator?.didAuthenticate(session)                  // the coordinator decides what's next
        } else if wasSubmitting, !viewModel.isSubmitting, !errors.isEmpty {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            if errors.email != nil { reveal(emailField) }
            else if errors.password != nil { reveal(passwordField) }
            else { reveal(banner) }
        }
        wasSubmitting = viewModel.isSubmitting
    }

    private func submitTapped() {
        view.endEditing(true)
        wasSubmitting = true
        Task { [weak self] in await self?.viewModel.submit() }
    }
}

// MARK: - Return key: Email → Password → submit

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            submitTapped()
        }
        return true
    }
}
