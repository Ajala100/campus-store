import UIKit
import StoreCore

/// Sign up (Create account).
///
///   (bag)  Create your account
///          Students only — sign up with your school email…
///   [ ! You’re offline… ]                         ← banner
///   Full name          [                    ]
///   School email       [                  ✉ ]
///   Matric number      [ (optional)         ]
///   Password           [                  👁 ]
///   ▮▮▮▯ Good                                     ← strength meter (appears as you type)
///   ✓ At least 8 characters                        ← live checklist
///   ✓ Upper- and lower-case letters (recommended)
///   ○ A number or a symbol (recommended)
///   Confirm password   [                  👁 ]
///   ✓ Passwords match
///   ☐ I agree to the Terms of Service…
///   [          Create account          ]
///   Already have an account?  Sign in
final class SignUpViewController: FormScreen {

    private let viewModel: SignUpViewModel
    weak var coordinator: AppCoordinator?

    private let banner = FormBannerView()
    private let nameField = StoreTextField(title: "Full name", placeholder: "Adaeze Okonkwo", trailingSystemImage: "person")
    private let emailField = StoreTextField(title: "School email", placeholder: "firstname.lastname@nutm.edu.ng", trailingSystemImage: "envelope")
    private let matricField = StoreTextField(title: "Matric number (optional)", placeholder: "NUTM/2026/0123", trailingSystemImage: "number")
    private let passwordField = StoreTextField(title: "Password", placeholder: "At least 8 characters")
    private let confirmField = StoreTextField(title: "Confirm password", placeholder: "Type it again")
    private let strengthView = PasswordStrengthView()
    private let rulesStack = UIStackView()
    private let matchRow = ChecklistRow()
    private let termsButton = UIButton(type: .system)
    private let termsError = UILabel()
    private lazy var submitButton = StoreButton(title: viewModel.submitTitle, style: .primary)
    private lazy var signInLink = makeLinkButton(prompt: viewModel.signInPrompt, action: viewModel.signInTitle)

    private var wasSubmitting = false
    private var reportedSignUp = false

    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("created in code") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()
        configureTerms()

        submitButton.addAction(UIAction { [weak self] _ in self?.submitTapped() }, for: .touchUpInside)
        signInLink.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.coordinator?.showSignIn(from: self.navigationController)
        }, for: .touchUpInside)

        rulesStack.axis = .vertical
        rulesStack.spacing = 6
        for _ in Validation.rules(for: "") { rulesStack.addArrangedSubview(ChecklistRow()) }

        let passwordGroup = UIStackView(arrangedSubviews: [passwordField, strengthView, rulesStack])
        passwordGroup.axis = .vertical
        passwordGroup.spacing = 10

        let confirmGroup = UIStackView(arrangedSubviews: [confirmField, matchRow])
        confirmGroup.axis = .vertical
        confirmGroup.spacing = StoreSpacing.tight

        let termsGroup = UIStackView(arrangedSubviews: [termsButton, termsError])
        termsGroup.axis = .vertical
        termsGroup.spacing = 2

        let form = UIStackView(arrangedSubviews: [nameField, emailField, matricField, passwordGroup, confirmGroup, termsGroup])
        form.axis = .vertical
        form.spacing = StoreSpacing.control

        let actions = UIStackView(arrangedSubviews: [submitButton, signInLink])
        actions.axis = .vertical
        actions.spacing = StoreSpacing.item

        [makeHeader(title: viewModel.title, subtitle: viewModel.subtitle), banner, form, actions]
            .forEach(content.addArrangedSubview)

        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)   // show "‹ Back"
    }

    // MARK: Setup

    private func configureFields() {
        nameField.textField.textContentType = .name
        nameField.textField.autocapitalizationType = .words
        nameField.textField.autocorrectionType = .no

        emailField.textField.keyboardType = .emailAddress
        emailField.textField.textContentType = .username
        emailField.textField.autocapitalizationType = .none
        emailField.textField.autocorrectionType = .no

        matricField.textField.autocapitalizationType = .allCharacters
        matricField.textField.autocorrectionType = .no
        matricField.textField.keyboardType = .asciiCapable

        passwordField.makePasswordField(isNew: true)       // iOS can suggest a strong password
        confirmField.makePasswordField(isNew: true)

        let order = [nameField, emailField, matricField, passwordField, confirmField]
        for field in order {
            field.textField.delegate = self
            field.textField.returnKeyType = field === confirmField ? .go : .next
        }

        bind(nameField) { $0.name = $1 }
        bind(emailField) { $0.email = $1 }
        bind(matricField) { $0.matric = $1 }
        bind(passwordField) { $0.password = $1 }
        bind(confirmField) { $0.confirmPassword = $1 }
    }

    /// One-way binding: every keystroke in `field` is copied into the ViewModel.
    private func bind(_ field: StoreTextField, _ assign: @escaping @MainActor (SignUpViewModel, String) -> Void) {
        field.textField.addAction(UIAction { [weak self, weak field] _ in
            guard let self, let field else { return }
            assign(self.viewModel, field.text)
        }, for: .editingChanged)
    }

    private func configureTerms() {
        var config = UIButton.Configuration.plain()
        config.title = viewModel.termsText
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = StoreColor.ink
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = StoreFont.body
            return out
        }
        termsButton.configuration = config
        termsButton.contentHorizontalAlignment = .leading
        termsButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.viewModel.acceptedTerms.toggle()
            UISelectionFeedbackGenerator().selectionChanged()
        }, for: .touchUpInside)

        termsError.font = StoreFont.caption
        termsError.textColor = StoreColor.danger
        termsError.numberOfLines = 0
        termsError.adjustsFontForContentSizeCategory = true
        termsError.isHidden = true
    }

    // MARK: Render

    private func render() {
        let errors = viewModel.errors
        nameField.error = errors.name
        emailField.error = errors.email
        matricField.error = errors.matric
        passwordField.error = errors.password
        confirmField.error = errors.confirmPassword
        banner.show(errors.form, kind: .error)

        // Password feedback only once the user starts typing, so an empty form stays calm.
        let typing = !viewModel.password.isEmpty
        strengthView.isHidden = !typing
        rulesStack.isHidden = !typing
        strengthView.strength = viewModel.passwordStrength
        let rows = rulesStack.arrangedSubviews.compactMap { $0 as? ChecklistRow }
        for (row, rule) in zip(rows, viewModel.passwordRules) {
            row.configure(title: rule.title + (rule.isRequired ? "" : " (recommended)"), isMet: rule.isMet)
        }

        matchRow.isHidden = viewModel.confirmPassword.isEmpty || errors.confirmPassword != nil
        matchRow.configure(title: viewModel.passwordsMatch ? "Passwords match" : "Passwords don’t match yet",
                           isMet: viewModel.passwordsMatch)

        // Terms checkbox: the icon is the state; red when it's the reason submit failed.
        let checked = viewModel.acceptedTerms
        let tint: UIColor = errors.terms != nil ? StoreColor.danger : (checked ? StoreColor.primary : StoreColor.muted)
        termsButton.configuration?.image = UIImage(systemName: checked ? "checkmark.square.fill" : "square")?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        termsButton.accessibilityValue = checked ? "Checked" : "Not checked"
        termsError.text = errors.terms
        termsError.isHidden = errors.terms == nil

        submitButton.isLoading = viewModel.isSubmitting
        signInLink.isEnabled = !viewModel.isSubmitting

        if case .signedUp(let session) = viewModel.phase, !reportedSignUp {
            reportedSignUp = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            coordinator?.didAuthenticate(session)          // a new account is signed in → Home
        } else if wasSubmitting, !viewModel.isSubmitting, !errors.isEmpty {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            revealFirstError(errors)
        }
        wasSubmitting = viewModel.isSubmitting
    }

    private func revealFirstError(_ errors: SignUpViewModel.FieldErrors) {
        switch errors.firstInvalidField {
        case .name?: reveal(nameField)
        case .email?: reveal(emailField)
        case .matric?: reveal(matricField)
        case .password?: reveal(passwordField)
        case .confirmPassword?: reveal(confirmField)
        case .terms?: reveal(termsButton)
        case nil: reveal(banner)
        }
    }

    private func submitTapped() {
        view.endEditing(true)
        wasSubmitting = true
        Task { [weak self] in await self?.viewModel.submit() }
    }
}

// MARK: - Return key walks down the form; the last field submits

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let order = [nameField, emailField, matricField, passwordField, confirmField].map(\.textField)
        if let index = order.firstIndex(where: { $0 === textField }), index + 1 < order.count {
            order[index + 1].becomeFirstResponder()
        } else {
            submitTapped()
        }
        return true
    }
}
