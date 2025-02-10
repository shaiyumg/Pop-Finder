import UIKit
import FirebaseAuth

class SignUpScreen: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self

        // Disables Keychain autofill suggestions (was bugging out my text fields)
        usernameTextField.textContentType = .none
        emailTextField.textContentType = .none
        passwordTextField.textContentType = .none
        confirmPasswordTextField.textContentType = .none
    }
    
    // Moves the user automatically to the next text field and presses signup when at the last text prompt
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            confirmPasswordTextField.resignFirstResponder()
            signUpButtonTapped(signUpButton) // Trigger signup
        }
        return true
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let username = usernameTextField.text ?? ""
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        // Local validation before Firebase call
        if username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showAlert(message: "Please fill in all fields.")
        } else if password != confirmPassword {
            showAlert(message: "Passwords do not match. Please try again.")
        } else if let passwordError = validatePassword(password) {
            showAlert(message: passwordError)
        } else {
            registerUser(username: username, email: email, password: password)
        }
    }

    // Function to validate password format before calling Firebase
    func validatePassword(_ password: String) -> String? {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).{6,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

        if !passwordTest.evaluate(with: password) {
            return "Your password must contain at least one uppercase letter, one lowercase letter, and one number."
        }
        return nil
    }

    // Register User and Store in Firestore
    func registerUser(username: String, email: String, password: String) {
        FirestoreManager.shared
            .registerUser(
                email: email,
                password: password,
                username: username
            ) { success, errorMessage in
            if success {
                self.showAlert(message: "Account created successfully! 🎉", shouldNavigateBack: true)
            } else {
                self.showAlert(message: errorMessage ?? "An error occurred. Please try again.")
            }
        }
    }

    // Alert function dialogue box
    func showAlert(message: String, shouldNavigateBack: Bool = false) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if shouldNavigateBack {
                // Navigate back to login screen after successful signup
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
