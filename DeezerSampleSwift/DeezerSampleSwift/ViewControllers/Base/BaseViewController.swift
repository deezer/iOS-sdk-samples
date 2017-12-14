import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    func setupNavigationBar() {
        if DeezerManager.sharedInstance.sessionState == .connected {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(logout))
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "login", style: .plain, target: self, action: #selector(login))
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
    }
    
    @objc func logout() {
        DeezerManager.sharedInstance.logout()
        NavigationManager.showSession()
    }
    
    @objc func login() {
        DeezerManager.sharedInstance.login()
    }
    
    @objc func search() {
        NavigationManager.showSelectType(from: self)
    }
}
