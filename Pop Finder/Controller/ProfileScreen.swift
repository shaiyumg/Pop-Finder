import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.image = UIImage(named: "Icon")

        // Make the profile picture circular
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true

        loadUserProfile()
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
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

    @IBAction func changeProfilePicture() {
        let alert = UIAlertController(title: "Change Profile Picture", message: "Choose a source", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))

        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .camera)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("Source type not available")
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        imagePicker.allowsEditing = true 

        present(imagePicker, animated: true, completion: nil)
    }

    // Allows the image to be actually applied once the picture has been taken/chosen aka Delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        logOutUser()
    }

    private func logOutUser() {
        do {
            try Auth.auth().signOut()

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
