import UIKit

extension UIViewController {
    
    class func makeFromStoryboard(nameStoryboard: String) -> UIViewController {
        let identifier = String(describing: self)
        
        return UIStoryboard(name: nameStoryboard, bundle: Bundle.main).instantiateViewController(withIdentifier:identifier)
    }
    
    func present(error: Error) {
        present(title: "Error", message: error.type.description)
    }
    
    func present(title: String, message: String, titleAction: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: titleAction, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        present(self, animated: true)
    }
}
