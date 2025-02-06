import UIKit
import FirebaseAuth

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
        
        // Disables Keychain autofill suggestions
        usernameTextField.textContentType = .none
        passwordTextField.textContentType = .none
        confirmPasswordTextField.textContentType = .none
    }
    
    // Moves the user automatically to the next text field and presses signup when at the last text prompt
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

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let email = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        // This validation is still required as this code validation checks locally while Firebase can only validate server-side information and will not be able to check these errors
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            showAlert(message: "Please fill in all fields.")
        } else if password != confirmPassword {
            showAlert(message: "Passwords do not match. Please try again.")
        } else if let passwordError = validatePassword(password) { //Client-side password validation
            showAlert(message: passwordError) // Show the custom error message if validation fails
        } else {
            registerUser(email: email, password: password)
        }
    }

    //Had to make a seperate validation for password policy as for some reason the Firebase error wasnt giving a correct one
    //Function to validate password client-side before calling Firebase
    func validatePassword(_ password: String) -> String? {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).{6,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

        if !passwordTest.evaluate(with: password) {
            return "Your password must contain at least one uppercase letter, one lowercase letter, and one number."
        }
        return nil
    }

    // User registering function with Firebase
    func registerUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let errorMessage = self.getFirebaseSignUpErrorMessage(error)
                self.showAlert(message: errorMessage)
            } else {
                self.showAlert(message: "Account created successfully! 🎉", shouldNavigateBack: true)
            }
        }
    }

    // Translate the raw Firebase error messages into normal error messages
    func getFirebaseSignUpErrorMessage(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        switch errorCode {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Try logging in instead."
        case AuthErrorCode.invalidEmail.rawValue:
            return "The email you entered is not valid. Please check and try again."
        case AuthErrorCode.networkError.rawValue:
            return "Network connection issue. Please check your internet and try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email. Please check and try again."
        default:
            return "An error occurred. Please try again later."
        }
    }

    // Alert function dialogue box
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
