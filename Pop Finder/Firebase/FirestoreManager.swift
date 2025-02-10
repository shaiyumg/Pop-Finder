import FirebaseAuth
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    // Registering users
    func registerUser(email: String, password: String, username: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let uid = authResult?.user.uid else {
                completion(false, "User ID not found.")
                return
            }

            let userData: [String: Any] = [
                "uid": uid,
                "email": email,
                "username": username
            ]

            self.db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    completion(false, "Firestore error: \(error.localizedDescription)")
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    // Fetch User Profile
    func fetchUser(uid: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = document?.data(),
                  let username = data["username"] as? String,
                  let email = data["email"] as? String else {
                completion(nil)
                return
            }

            let user = UserProfile(uid: uid, username: username, email: email)
            completion(user)
        }
    }
}
