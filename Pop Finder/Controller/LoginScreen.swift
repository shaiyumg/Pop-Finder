import UIKit

class LoginScreen: UIViewController, UITextFieldDelegate{

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
       }

    //    Moves the user automatically to the next text field and presses signup when at the last text prompt
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginButtonTapped(loginButton)
        }
        return true
    }
       @objc func loginFromKeyboard() {
           loginButtonTapped(loginButton)
    }
//Function for when the login button is pressed
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
//Adding robustness to login
        if username.isEmpty || password.isEmpty {
            showAlert(message: "Please enter both username and password.")
        } else {
            authenticateUser(username: username, password: password)
        }
    }
//Activates segue to signup screen
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToSignUp", sender: self)
    }
    
//Need to find a way to authenticate multiple users
    func authenticateUser(username: String, password: String) {
        // Dummy authentication for now
        if username == "shaiyumg" && password == "password123" {
            showAlert(message: "Login Successful! 🎉")
        } else {
            showAlert(message: "Invalid username or password. Try again.")
        }
    }
//Function for the alert itself
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
