import UIKit

/// Creates the window in code (no storyboard) and hands it to the coordinator.
/// After this, the scene delegate never mentions a screen again.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.tintColor = StoreColor.primary
        self.window = window
        let coordinator = AppCoordinator(window: window)
        self.coordinator = coordinator
        coordinator.start()
    }
}
