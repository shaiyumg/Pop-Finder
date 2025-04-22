import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    private let uploadIndicator = UIActivityIndicatorView(style: .large)
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
        
        // Setup upload activity indicator
        uploadIndicator.hidesWhenStopped = true
        uploadIndicator.center = view.center
        view.addSubview(uploadIndicator)
        
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
                let pfpURLString = data?["userPFP"] as? String
                
                DispatchQueue.main.async {
                    // Set username
                    self.usernameLabel.text = username
                    
                    // Load and set profile picture if available
                    if let urlString = pfpURLString, let url = URL(string: urlString) {
                        URLSession.shared.dataTask(with: url) { data, _, error in
                            guard let data = data, error == nil, let image = UIImage(data: data) else { return }
                            DispatchQueue.main.async {
                                self.profileImageView.image = image
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    // ML Model Download
    private func downloadMLModel() {
        let isModelDownloaded = UserDefaults.standard.bool(forKey: "MLModelDownloaded")
        
        // Check if model is already downloaded
        DispatchQueue.main.async {
            self.mlModelActivityIndicator.stopAnimating()
            
            if isModelDownloaded {
                self.mlModelStatusLabel.text = "ML Model Installed"
            } else {
                self.mlModelStatusLabel.text = "Downloading Model..."
                
                MLModelManager.shared.downloadMLModel { [weak self] success in
                    DispatchQueue.main.async {
                        if success {
                            self?.mlModelStatusLabel.text = "ML Model Installed"
                            UserDefaults.standard.set(true, forKey: "MLModelDownloaded")
                        } else {
                            self?.mlModelStatusLabel.text = "Failed to Install Model"
                        }
                    }
                }
            }
        }
    }
    
    // Updates ML Model Progress on Profile Screen
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
        picker.dismiss(animated: true, completion: nil)
        // Begin upload state
        setUploading(true)
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            self.profileImageView.image = selectedImage
            // Upload to Cloudinary and save URL to Firestore
            uploadImageToCloudinary(image: selectedImage) { [weak self] url in
                // End upload state
                self?.setUploading(false)
                if let imageUrl = url {
                    self?.updateUserProfileImageURL(url: imageUrl)
                } else {
                    print("Image upload failed.")
                }
            }
        }
    }
    
    // UIImagePickerControllerDelegate method to handle cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func uploadImageToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { completion(nil); return }
        let url = URL(string: "https://api.cloudinary.com/v1_1/popfinder/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        // Append upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("userPFP\r\n".data(using: .utf8)!)
        // Append image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        URLSession.shared.uploadTask(with: request, from: body) { data, _, error in
            // Invoke completion with nil on failure or missing secure_url
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let secureUrl = json["secure_url"] as? String else {
                completion(nil)
                return
            }
            completion(secureUrl)
        }.resume()
    }
    
    // Updates the user's Firestore document with the profile image URL.
    private func updateUserProfileImageURL(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["userPFP": url]) { error in
            if let error = error { print("Error updating profile image URL: \(error.localizedDescription)") }
            else { print("Profile image URL successfully updated.") }
        }
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
    //Enables/disables user interaction and shows/hides the upload indicator
    private func setUploading(_ uploading: Bool) {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = !uploading
            // Prevent navigation gestures or modal swipe-dismiss
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = !uploading
            self.isModalInPresentation = uploading

            // Disable action buttons
            self.changePhotoButton.isEnabled = !uploading
            self.logoutButton.isEnabled = !uploading

            if uploading {
                self.uploadIndicator.startAnimating()
            } else {
                self.uploadIndicator.stopAnimating()
            }
        }
    }
}
