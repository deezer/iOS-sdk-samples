import UIKit

class DeezerSessionViewController: UIViewController {
    
    @IBOutlet private weak var loginButton: UIButton!
    
    // MARK: - Actions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if DeezerManager.sharedInstance.sessionState == .connected {
            NavigationManager.showOnBoarding()
            return
        }
        DeezerManager.sharedInstance.loginResult = sessionDidLogin
    }
    
    // MARK: - Actions
    
    @IBAction func login() {
        loginButton.isEnabled = false
        DeezerManager.sharedInstance.login()
    }
    
    func sessionDidLogin(result: ResultLogin) {
        switch result {
        case .success:
            NavigationManager.showOnBoarding()
        case let .error(error):
            if let error = error, error.type == .noConnection {
                present(error: error)
            }
            loginButton.isEnabled = true
        case .logout:
            break
        }
    }
}
