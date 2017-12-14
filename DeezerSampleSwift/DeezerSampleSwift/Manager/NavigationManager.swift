import Foundation

struct NavigationManager {
    
    static func showSession() {
        let sessionViewController = DeezerSessionViewController.makeFromStoryboard(nameStoryboard: "Main")
        UIApplication.shared.keyWindow?.rootViewController = sessionViewController
    }
    
    static func showOnBoarding() {
        let rootViewController = DeezerFavoriteViewController.makeFromStoryboard(nameStoryboard: "Main")
        let baseNavigation = UINavigationController(rootViewController: rootViewController)
        if let window = UIApplication.shared.delegate?.window {
            window?.rootViewController = baseNavigation
        }
    }
    
    static func showObjectList(from viewController: UIViewController, object: DeezerObject) {
        guard let newViewController = DeezerObjectListViewController.makeFromStoryboard(nameStoryboard: "Main") as? DeezerObjectListViewController else {
            return
        }
        newViewController.object = object
        viewController.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    static func showSearch(from viewController: UIViewController, type: DeezerObjectType) {
        guard let searchViewController = DeezerSearchViewController.makeFromStoryboard(nameStoryboard: "Main") as? DeezerSearchViewController else {
            return
        }
        searchViewController.type = type
        viewController.navigationController?.pushViewController(searchViewController, animated: true)
    }
    
    static func showSelectType(from viewController: UIViewController) {
        guard let selectTypeViewController = DeezerSelectTypeViewController.makeFromStoryboard(nameStoryboard: "Main") as? DeezerSelectTypeViewController else {
            return
        }
        viewController.navigationController?.pushViewController(selectTypeViewController, animated: true)
    }
    
    static func showPlayer(from viewController: UIViewController, playable: DZRPlayable, index: Int) {
        guard let deezerPlayerViewController = DeezerPlayerViewController.makeFromStoryboard(nameStoryboard: "Main") as? DeezerPlayerViewController else {
            return
        }
        deezerPlayerViewController.configure(playable: playable, currentIndex: index)
        viewController.navigationController?.pushViewController(deezerPlayerViewController, animated: true)
    }
    
}
