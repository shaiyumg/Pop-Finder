import UIKit

class MainScreen: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func profilePressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToProfile", sender: self)
    }
    
}
