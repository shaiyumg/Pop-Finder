import UIKit

class SignUpScreen: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
    }
//    Moves the user automatically to the next text field and presses signup when at the last text prompt
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            // Hide the keyboard and trigger Sign Up
            confirmPasswordTextField.resignFirstResponder()
            signUpButtonTapped(signUpButton)
        }
        return true
    }
    @objc func signUpFromKeyboard() {
        signUpButtonTapped(signUpButton)
    }

    // Action for Sign-Up Button
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        // Basic validation
        if username.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showAlert(message: "Please fill in all fields.")
        } else if password != confirmPassword {
            showAlert(message: "Passwords do not match. Please try again.")
        } else {
            registerUser(username: username, password: password)
        }
    }

    // Dummy user registration (this could save to a database)
    func registerUser(username: String, password: String) {
        showAlert(message: "Account created successfully! 🎉", shouldNavigateBack: true)
    }

    func showAlert(message: String, shouldNavigateBack: Bool = false) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if shouldNavigateBack {
                // Navigate back ONLY once the account is created
                if let navController = self.navigationController {
                    navController.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}
