import UIKit
import FirebaseFirestore
import SDWebImage

class SkullPandaController: UIViewController {
    
    @IBOutlet weak var figurineImageView: UIImageView!
    @IBOutlet weak var figurineNameLabel: UILabel!
    
    var mainDocumentID: String?
    var subCollection: String?
    var subDocumentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch Firestore data dynamically
        if let mainDocID = mainDocumentID, let subCol = subCollection, let subDocID = subDocumentID {
            fetchFigurineData(mainDocumentID: mainDocID, subCollection: subCol, subDocumentID: subDocID)
        }
    }
    
    // Fetch Figurine Data from Firestore
    func fetchFigurineData(mainDocumentID: String, subCollection: String, subDocumentID: String) {
        let db = Firestore.firestore()
        
        let documentRef = db.collection("figurines")
                            .document(mainDocumentID)
                            .collection(subCollection)
                            .document(subDocumentID)
        
        documentRef.getDocument { (document, error) in
            if error != nil {
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()

                // Extract valid URL
                if let rawURL = data?["imageurl"] as? String ?? data?["imageURL"] as? String {
                    let cleanedURL = self.cleanImageUrl(rawURL)
                    
                    if let validURL = cleanedURL {
                        DispatchQueue.main.async {
                            self.figurineNameLabel.text = data?["name"] as? String ?? "Unknown Figurine"
                            self.loadImage(from: validURL)
                        }
                    }
                }
            }
        }
    }

    // Clean and validate Firestore image URL
    func cleanImageUrl(_ url: String) -> String? {
        var cleanedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedURL = cleanedURL.replacingOccurrences(of: " ", with: "%20")  // Encode spaces

        if !cleanedURL.lowercased().hasPrefix("http") {
            cleanedURL = "https://" + cleanedURL
        }

        guard let encodedURL = cleanedURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              URL(string: encodedURL) != nil else {
            return nil
        }
        
        return encodedURL
    }

    // Load Image from URL
    func loadImage(from url: String) {
        guard let imageURL = URL(string: url) else {
            return
        }

        figurineImageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "placeholder"))
    }
}
