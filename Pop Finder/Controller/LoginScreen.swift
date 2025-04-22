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
        
        // Disable autofill for username field to avoid UIKit errors
        usernameTextField.textContentType = .oneTimeCode
        usernameTextField.autocorrectionType = .no
        usernameTextField.spellCheckingType = .no
        
        // Delay first responder activation (fix keyboard lag)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.usernameTextField.becomeFirstResponder()
        }
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
    
    // Prefill email and password on the Signup screen when navigating
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "goToSignUp",
              let signupVC = segue.destination as? SignUpScreen else {
            return
        }
        // Ensure outlets are loaded before setting
        signupVC.loadViewIfNeeded()

        // Prefill with existing login inputs
        if let email = usernameTextField.text, !email.isEmpty {
            signupVC.emailTextField.text = email
        }
        if let password = passwordTextField.text, !password.isEmpty {
            signupVC.passwordTextField.text = password
        }
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
        let nsError = error as NSError
        if let authError = AuthErrorCode(rawValue: nsError.code) {
            switch authError {
            case .networkError:
                return "Network error. Please check your internet connection."
            case .userNotFound, .wrongPassword, .invalidCredential:
                return "Incorrect login details. Please check your email and password."
            case .invalidEmail:
                return "Invalid email format. Please enter a valid email."
            case .userDisabled:
                return "Your account has been disabled. Please contact support."
            case .tooManyRequests:
                return "Too many attempts. Please try again later."
            default:
                return "An unknown error occurred. Please try again."
            }
        }
        // Fallback for non-auth errors
        return "An unknown error occurred. Please try again."
    }
    
    // Displays an alert message to the user
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        
        alert.addAction(okAction)
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
