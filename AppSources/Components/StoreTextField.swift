import UIKit

/// A labelled text field with an optional trailing icon button and an inline error line.
///
///   Email                      ← title label
///   ┌──────────────────────┐
///   │ you@nutm.edu.ng    ✉ │   ← the UITextField + trailing icon
///   └──────────────────────┘
///   Enter a valid email.       ← error label (hidden when nil)
///
/// Screens talk to it through a small surface (`text`, `error`, `textField`), never by
/// reaching into its subviews. The screen decides WHAT is an error; this view decides how
/// an error LOOKS (red border + red text), so every form in the app looks the same.
final class StoreTextField: UIView {

    let textField = UITextField()
    private let titleLabel = UILabel()
    private let errorLabel = UILabel()
    private let container = UIView()
    private let trailingButton = UIButton(type: .system)

    var text: String { textField.text ?? "" }

    var error: String? {
        didSet {
            errorLabel.text = error
            errorLabel.isHidden = error == nil
            updateBorder()
            textField.accessibilityHint = error          // VoiceOver reads the error too
        }
    }

    init(title: String, placeholder: String, trailingSystemImage: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = StoreFont.caption
        titleLabel.textColor = StoreColor.textSecondary
        titleLabel.adjustsFontForContentSizeCategory = true

        container.backgroundColor = StoreColor.surface
        container.layer.cornerRadius = StoreRadius.control
        container.layer.borderWidth = 1
        container.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = placeholder
        textField.font = StoreFont.body
        textField.textColor = StoreColor.ink
        textField.adjustsFontForContentSizeCategory = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityLabel = title
        textField.addTarget(self, action: #selector(focusChanged), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(focusChanged), for: .editingDidEnd)

        errorLabel.font = StoreFont.caption
        errorLabel.textColor = StoreColor.danger
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.isHidden = true

        trailingButton.tintColor = StoreColor.muted
        trailingButton.translatesAutoresizingMaskIntoConstraints = false
        if let name = trailingSystemImage {
            trailingButton.setImage(UIImage(systemName: name), for: .normal)
        } else {
            trailingButton.isHidden = true
        }

        container.addSubview(textField)
        container.addSubview(trailingButton)

        let stack = UIStackView(arrangedSubviews: [titleLabel, container, errorLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            textField.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            trailingButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            trailingButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            trailingButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            trailingButton.widthAnchor.constraint(equalToConstant: 28),
            trailingButton.heightAnchor.constraint(equalToConstant: 28),
        ])
        updateBorder()
    }

    required init?(coder: NSCoder) { fatalError("StoreTextField is created in code") }

    /// Runs `action` when the trailing icon is tapped (e.g. show/hide password).
    func onTrailingTap(_ action: @escaping () -> Void) {
        trailingButton.addAction(UIAction { _ in action() }, for: .touchUpInside)
    }

    func setTrailingImage(_ systemName: String, accessibilityLabel: String?) {
        trailingButton.setImage(UIImage(systemName: systemName), for: .normal)
        trailingButton.isHidden = false
        trailingButton.accessibilityLabel = accessibilityLabel
    }

    /// Makes a password field: hidden text plus an eye button that reveals it.
    func makePasswordField(isNew: Bool) {
        textField.isSecureTextEntry = true
        textField.textContentType = isNew ? .newPassword : .password
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        setTrailingImage("eye", accessibilityLabel: "Show password")
        onTrailingTap { [weak self] in
            guard let self else { return }
            self.textField.isSecureTextEntry.toggle()
            let hidden = self.textField.isSecureTextEntry
            self.setTrailingImage(hidden ? "eye" : "eye.slash", accessibilityLabel: hidden ? "Show password" : "Hide password")
        }
    }

    // MARK: Border: red for an error, blue while typing, grey otherwise

    @objc private func focusChanged() { updateBorder() }

    private func updateBorder() {
        let color: UIColor
        if error != nil { color = StoreColor.danger }
        else if textField.isFirstResponder { color = StoreColor.primary }
        else { color = StoreColor.line }
        container.layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
        container.layer.borderWidth = textField.isFirstResponder || error != nil ? 1.5 : 1
    }

    /// CALayer colours don't follow dark mode on their own; re-apply when the theme changes.
    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        updateBorder()
    }
}
