import UIKit

/// The layout both auth screens share: a vertical stack inside a scroll view that ends
/// where the keyboard begins. Subclasses just add their views to `content`.
///
///   ┌ safe area ───────────────┐
///   │ UIScrollView             │
///   │  └ UIStackView `content` │  ← one column, 20pt page margins, scrolls vertically only
///   ├──────────────────────────┤  ← keyboardLayoutGuide.top: moves up with the keyboard
///   │       (keyboard)         │
///   └──────────────────────────┘
///
/// `keyboardLayoutGuide` (iOS 15+) replaces the old keyboard-notification code: when the
/// keyboard appears, the scroll view shrinks and the form becomes scrollable, so a field is
/// never hidden behind the keyboard.
class FormScreen: UIViewController {

    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive     // drag down to hide the keyboard
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    let content: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = StoreSpacing.section
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StoreColor.background
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: StoreSpacing.section),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: StoreSpacing.page),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -StoreSpacing.page),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -StoreSpacing.section),
            // As wide as the screen minus margins → scrolls vertically only.
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * StoreSpacing.page),
        ])

        // Tap anywhere outside a field to dismiss the keyboard.
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    /// Header used by both screens: logo, big title, one line of explanation.
    func makeHeader(title: String, subtitle: String) -> UIView {
        let heading = UILabel()
        heading.text = title
        heading.font = StoreFont.display
        heading.textColor = StoreColor.ink
        heading.numberOfLines = 0
        heading.adjustsFontForContentSizeCategory = true
        heading.accessibilityTraits = .header

        let sub = UILabel()
        sub.text = subtitle
        sub.font = StoreFont.body
        sub.textColor = StoreColor.textSecondary
        sub.numberOfLines = 0
        sub.adjustsFontForContentSizeCategory = true

        let badge = makeLogoBadge()
        let badgeRow = UIStackView(arrangedSubviews: [badge, UIView()])   // keeps the badge at 64pt, left-aligned
        badgeRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [badgeRow, heading, sub])
        stack.axis = .vertical
        stack.spacing = StoreSpacing.tight
        stack.setCustomSpacing(StoreSpacing.control, after: badgeRow)
        return stack
    }

    /// After a failed submit, scroll the first problem into view and move focus to it.
    func reveal(_ target: UIView) {
        let rect = target.convert(target.bounds, to: scrollView).insetBy(dx: 0, dy: -StoreSpacing.section)
        scrollView.scrollRectToVisible(rect, animated: true)
        if let field = target as? StoreTextField { field.textField.becomeFirstResponder() }
        UIAccessibility.post(notification: .layoutChanged, argument: target)
    }
}
