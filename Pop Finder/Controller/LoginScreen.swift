import UIKit
import FirebaseAuth

class LoginScreen: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    // Loading Indicator
    let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegates
        usernameTextField.delegate = self
        passwordTextField.delegate = self
                
        // Setup Loading Indicator
        setupLoadingIndicator()
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

    // Dismiss keyboard when tapping outside of a text field
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
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
    
    // Authenticate user and store username in UserDefaults
    func authenticateUser(email: String, password: String) {
        
        // Start loading animation and disable login button
        loadingIndicator.startAnimating()
        loginButton.isEnabled = false
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                // Stop loading animation and re-enable login button
                self.loadingIndicator.stopAnimating()
                self.loginButton.isEnabled = true
            }
            
            if let error = error {
                let friendlyErrorMessage = self.getFirebaseLoginErrorMessage(error)
                self.showAlert(message: friendlyErrorMessage)
            } else {
                guard let uid = authResult?.user.uid else {
                    self.showAlert(message: "An error occurred. Please try again.")
                    return
                }

                // Fetch username from Firestore after login
                FirestoreManager.shared.fetchUser(uid: uid) { user in
                    if let user = user {
                        // Store username in UserDefaults to then display the user in the profile screen
                        UserDefaults.standard.set(user.username, forKey: "username")
                        
                        self.showAlert(message: "Login Successful! 🎉") {
                            self.switchToMainScreen()
                        }
                    } else {
                        self.showAlert(message: "Failed to retrieve user data.")
                    }
                }
            }
        }
    }
    
    // Transition to the main screen after login
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
    
    // Reset password function
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
    
    // Convert Firebase errors into user-friendly messages
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
    
    // Display alert messages
    func showAlert(title: String = "Notice", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }
    
    // Setup Loading Indicator
    func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .gray
        view.addSubview(loadingIndicator)
        
        // Center the loading indicator in the view
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
