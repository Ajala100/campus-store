import UIKit

/// The app's two button styles, defined once. Every screen just says
/// `StoreButton(title: "Sign in", style: .primary)`.
final class StoreButton: UIButton {

    enum Style { case primary, secondary }

    init(title: String, style: Style) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        var config: UIButton.Configuration
        switch style {
        case .primary:
            config = .filled()
            config.baseBackgroundColor = StoreColor.primary
            config.baseForegroundColor = StoreColor.onPrimary
        case .secondary:
            config = .plain()
            config.baseForegroundColor = StoreColor.primary
            config.background.backgroundColor = StoreColor.surface
            config.background.strokeColor = StoreColor.line
            config.background.strokeWidth = 1
        }
        config.title = title
        config.cornerStyle = .fixed
        config.background.cornerRadius = StoreRadius.control
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = StoreFont.button
            return out
        }
        configuration = config

        // 52pt tall: comfortably above Apple's 44pt minimum touch target.
        heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("StoreButton is created in code") }

    /// Spinner inside the button while a request is in flight; also blocks double-taps.
    var isLoading: Bool = false {
        didSet {
            configuration?.showsActivityIndicator = isLoading
            isEnabled = !isLoading
        }
    }
}
