import UIKit
import StoreCore

/// Home — where a signed-in student lands. Kept deliberately simple: the assignment is
/// the auth flow; Home exists to prove the session works (name shown, survives relaunch,
/// Sign out returns to Sign in).
final class HomeViewController: UITableViewController {

    private let user: User
    private let products = Product.samples
    weak var coordinator: AppCoordinator?

    init(user: User) {
        self.user = user
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("created in code") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hi, \(user.firstName)"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.backgroundColor = StoreColor.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "product")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign out", image: nil, primaryAction: UIAction { [weak self] _ in
            self?.confirmSignOut()
        }, menu: nil)
    }

    private func confirmSignOut() {
        let alert = UIAlertController(title: "Sign out?", message: "You’ll need your password to sign back in.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Sign out", style: .destructive) { [weak self] _ in self?.coordinator?.signOut() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem   // iPad safety
        present(alert, animated: true)
    }

    // MARK: Table

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Your account" : "Popular on campus"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "product", for: indexPath)
        var config = UIListContentConfiguration.subtitleCell()
        if indexPath.section == 0 {
            config.text = user.fullName
            config.secondaryText = [user.email, user.matricNumber].compactMap { $0 }.joined(separator: " · ")
            config.image = UIImage(systemName: "person.crop.circle.fill")
            cell.selectionStyle = .none
        } else {
            let product = products[indexPath.row]
            config.text = product.name
            config.secondaryText = product.formattedPrice
            config.image = UIImage(systemName: product.symbol)
            cell.selectionStyle = .default
        }
        config.imageProperties.tintColor = StoreColor.primary
        config.secondaryTextProperties.color = StoreColor.textSecondary
        cell.contentConfiguration = config
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
