import UIKit
import StoreCore

/// A coloured banner for messages that belong to the whole form, not one field:
/// errors (wrong password, offline, locked) in red, information (reset link sent) in green.
final class FormBannerView: UIView {

    enum Kind { case error, info }

    private let icon = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = StoreRadius.control

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.setContentHuggingPriority(.required, for: .horizontal)
        label.font = StoreFont.body
        label.textColor = StoreColor.ink
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = StoreSpacing.item
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: StoreSpacing.item),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: StoreSpacing.control),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -StoreSpacing.control),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -StoreSpacing.item),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
        ])
        isAccessibilityElement = true
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("created in code") }

    /// nil hides the banner.
    func show(_ message: String?, kind: Kind = .error) {
        label.text = message
        accessibilityLabel = message
        isHidden = message == nil
        switch kind {
        case .error:
            backgroundColor = StoreColor.dangerSoft
            icon.image = UIImage(systemName: "exclamationmark.triangle.fill")
            icon.tintColor = StoreColor.danger
        case .info:
            backgroundColor = StoreColor.successSoft
            icon.image = UIImage(systemName: "checkmark.circle.fill")
            icon.tintColor = StoreColor.success
        }
    }
}

/// Four bars that fill and change colour with password strength, plus the word ("Good").
/// Colour is never the only signal — the word says the same thing for colour-blind users.
final class PasswordStrengthView: UIView {

    private let bars: [UIView] = (0..<4).map { _ in
        let bar = UIView()
        bar.layer.cornerRadius = 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.heightAnchor.constraint(equalToConstant: 4).isActive = true
        return bar
    }
    private let label = UILabel()

    var strength: Validation.Strength = .empty { didSet { update() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let barStack = UIStackView(arrangedSubviews: bars)
        barStack.axis = .horizontal
        barStack.spacing = 6
        barStack.distribution = .fillEqually

        label.font = StoreFont.caption
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [barStack, label])
        row.axis = .horizontal
        row.spacing = StoreSpacing.item
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        isAccessibilityElement = true
        accessibilityLabel = "Password strength"
        update()
    }

    required init?(coder: NSCoder) { fatalError("created in code") }

    private func update() {
        let color: UIColor
        switch strength {
        case .empty, .weak:  color = StoreColor.danger
        case .fair:          color = StoreColor.accent
        case .good, .strong: color = StoreColor.success
        }
        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = index < strength.rawValue ? color : StoreColor.line
        }
        label.text = strength.label
        label.textColor = color
        accessibilityValue = strength.label
    }
}

/// "✓ At least 8 characters" — turns green when the rule is met.
final class ChecklistRow: UIView {

    private let icon = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        label.font = StoreFont.caption
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = StoreSpacing.tight
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("created in code") }

    func configure(title: String, isMet: Bool) {
        icon.image = UIImage(systemName: isMet ? "checkmark.circle.fill" : "circle")
        icon.tintColor = isMet ? StoreColor.success : StoreColor.muted
        label.text = title
        label.textColor = isMet ? StoreColor.ink : StoreColor.textSecondary
        accessibilityLabel = title
        accessibilityValue = isMet ? "Done" : "Not yet"
    }
}

/// The round logo badge at the top of the auth screens (an SF Symbol, so no image assets needed).
@MainActor
func makeLogoBadge(symbol: String = "bag.fill") -> UIView {
    let ring = UIView()
    ring.translatesAutoresizingMaskIntoConstraints = false
    ring.backgroundColor = StoreColor.primarySoft
    ring.layer.cornerRadius = 32
    let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)))
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.tintColor = StoreColor.primary
    ring.addSubview(icon)
    NSLayoutConstraint.activate([
        ring.widthAnchor.constraint(equalToConstant: 64),
        ring.heightAnchor.constraint(equalToConstant: 64),
        icon.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
        icon.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
    ])
    ring.isAccessibilityElement = false
    return ring
}

/// "New to Campus Store?  Create an account" — grey question, blue action, one button.
@MainActor
func makeLinkButton(prompt: String, action: String) -> UIButton {
    let button = UIButton(type: .system)
    let title = NSMutableAttributedString(string: prompt + "  ",
                                          attributes: [.font: StoreFont.body, .foregroundColor: StoreColor.textSecondary])
    title.append(NSAttributedString(string: action,
                                    attributes: [.font: StoreFont.bodyBold, .foregroundColor: StoreColor.primary]))
    button.setAttributedTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .center
    button.accessibilityLabel = "\(prompt) \(action)"
    return button
}
