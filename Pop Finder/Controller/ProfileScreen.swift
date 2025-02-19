import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    @IBOutlet weak var mlModelStatusLabel: UILabel!
    @IBOutlet weak var mlModelActivityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.image = UIImage(named: "Icon")

        // Make the profile picture circular
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true

        loadUserProfile()

        // Start ML Model Download Process
        mlModelStatusLabel.text = "Checking model..."
        mlModelActivityIndicator.startAnimating()
        
        downloadMLModel()
    }

    // Fetches user profile data from Firestore
    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return } // Ensure user is logged in

        let db = Firestore.firestore()
        
        // Retrieve user data from Firestore
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let username = data?["username"] as? String ?? "No username"

                DispatchQueue.main.async {
                    self.usernameLabel.text = username
                }
            }
        }
    }

    // ML Model Download
    private func downloadMLModel() {
        MLModelManager.shared.downloadMLModel { [weak self] path in
            DispatchQueue.main.async {
                self?.mlModelActivityIndicator.stopAnimating()
                if path != nil {
                    self?.mlModelStatusLabel.text = "ML Model Installed"
                } else {
                    self?.mlModelStatusLabel.text = "Failed to Install Model"
                }
            }
        }
    }
    //Updates ML Model Progress on Profile Screen
    @objc private func updateMLModelProgress(_ notification: Notification) {
            if let progress = notification.userInfo?["progress"] as? Int {
                DispatchQueue.main.async {
                    self.mlModelStatusLabel.text = "Downloading Model: \(progress)%"
                }
            }
        }
    
    // Opens the image picker for the selected source type (camera or photo library)
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("Selected source type is not available.")
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method to handle the selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegate method to handle cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // Presents an action sheet for changing the profile picture
    @IBAction func changeProfilePicture() {
        let alert = UIAlertController(title: "Change Profile Picture", message: "Choose a source", preferredStyle: .actionSheet)

        // Option to select an image from the photo library
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))

        // Option to take a new photo using the camera
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .camera)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // Present the action sheet
        present(alert, animated: true, completion: nil)
    }

    // Logs out the user and navigates back to the login screen
    @IBAction func logoutTapped(_ sender: UIButton) {
        logOutUser()
    }

    private func logOutUser() {
        do {
            try Auth.auth().signOut() // Firebase sign out

            // Get reference to the main window
            guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                print("Error: Unable to retrieve SceneDelegate or window.")
                return
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginScreen = storyboard.instantiateViewController(identifier: "LoginScreen")

            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.3

            window.layer.add(transition, forKey: kCATransition)
            window.rootViewController = loginScreen
            window.makeKeyAndVisible()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
