import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        /// This command makes the user automatically press login when pressing enter/return while in the password field
        passwordTextField.addTarget(self, action: #selector(loginFromKeyboard), for: .editingDidEndOnExit)
       }

       @objc func loginFromKeyboard() {
           loginButtonTapped(loginButton)
    }
///Function for when 
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        if username.isEmpty || password.isEmpty {
            showAlert(message: "Please enter both email and password.")
        } else {
            authenticateUser(username: username, password: password)
        }
    }

    func authenticateUser(username: String, password: String) {
        // Dummy authentication for now
        if username == "shaiyumg" && password == "password123" {
            showAlert(message: "Login Successful! 🎉")
        } else {
            showAlert(message: "Invalid email or password. Try again.")
        }
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
