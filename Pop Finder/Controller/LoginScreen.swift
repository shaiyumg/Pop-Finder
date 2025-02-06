import UIKit
import FirebaseAuth

class LoginScreen: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    // Moves the user automatically to the next text field and triggers login when at the last field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            if let email = usernameTextField.text, let password = passwordTextField.text {
                authenticateUser(email: email, password: password)
            }
        }
        return true
    }
    
    // Function for when the login button is pressed
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        let email = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        if email.isEmpty || password.isEmpty {
            showAlert(message: "Please enter both email and password.")
        } else {
            authenticateUser(email: email, password: password)
        }
    }
    
    // Activates segue to signup screen
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToSignUp", sender: self)
    }
    
    // Authenticate user using Firebase
    func authenticateUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                let friendlyErrorMessage = self.getFirebaseLoginErrorMessage(error)
                self.showAlert(message: friendlyErrorMessage)
            } else {
                self.showAlert(message: "Login Successful! 🎉") {
                    self.switchToMainScreen()
                }
            }
        }
    }
    
    // Switch to main screen after successful login
    func switchToMainScreen() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
              let window = sceneDelegate.window else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let mainTabBarController = storyboard.instantiateViewController(identifier: "Main") as? UITabBarController {
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.3
            
            window.layer.add(transition, forKey: kCATransition)
            window.rootViewController = mainTabBarController
            window.makeKeyAndVisible()
        }
    }

    // Function to reset the password
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                let friendlyErrorMessage = self.getFirebaseLoginErrorMessage(error)
                self.showAlert(message: friendlyErrorMessage)
            } else {
                self.showAlert(message: "A password reset link has been sent to \(email).")
            }
        }
    }
    
    // Forgot Password Button Action
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Reset Password", message: "Enter your email to reset your password.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        let sendAction = UIAlertAction(title: "Send Reset Link", style: .default) { _ in
            if let email = alert.textFields?.first?.text {
                self.resetPassword(email: email)
            }
        }
        
        alert.addAction(sendAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    // Function for translating Firebase error codes into user-friendly messages
    func getFirebaseLoginErrorMessage(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        switch errorCode {
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email. Please sign up or try again."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again or reset your password."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email format. Please enter a valid email."
        case AuthErrorCode.userDisabled.rawValue:
            return "Your account has been disabled. Please contact support."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        default:
            return "An unknown error occurred. Please try again."
        }
    }
    
    // Function for showing alerts
    func showAlert(title: String = "Notice", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}
