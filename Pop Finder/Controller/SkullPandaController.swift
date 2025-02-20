import UIKit
import FirebaseFirestore
import SDWebImage

class SkullPandaController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Variables to store Firestore document and subcollection paths
    var mainDocumentID: String?
    var subCollection: String?
    var subDocumentID: String?
    var secondSubCollection: String?
    var secondSubDocumentID: String?
    
    // Arrays to store retrieved figurine data
    var figurines: [(name: String, imageUrl: String, price: Double)] = []
    var secondFigurine: (name: String, imageUrl: String, price: Double)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set collectionView delegates
        collectionView.delegate = self
        collectionView.dataSource = self

        // Configure CollectionView layout for horizontal swiping
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal  // Enables left-right swiping
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        collectionView.collectionViewLayout = layout
        // Enables smooth swipe effect
        collectionView.isPagingEnabled = true

        // Fetch figurine data from Firestore
        fetchAllFigurines()
        fetchSecondFigurine()
    }

    // Fetch all figurines from the Firestore subcollection
    func fetchAllFigurines() {
        // Ensure required Firestore paths are set before querying
        guard let mainID = mainDocumentID, let subCol = subCollection else { return }

        let db = Firestore.firestore()
        
        // Access the specific subcollection inside the given main document
        db.collection("figurines").document(mainID).collection(subCol).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else { return }

            // Process retrieved documents and extract figurine details
            self.figurines = documents.compactMap { document in
                let data = document.data()
                let name = data["name"] as? String ?? "Unknown"
                let rawImageUrl = data["imageurl"] as? String ?? data["imageURL"] as? String ?? ""
                let price = data["price"] as? Double ?? 0.0

                return (name, self.cleanImageUrl(rawImageUrl) ?? "", price)
            }

            // Update the UI after retrieving data
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    // Fetches the second figurine from a different Firestore subcollection
    func fetchSecondFigurine() {
        // Ensure Firestore paths for the second figurine are valid before querying
        guard let mainID = mainDocumentID, let secondSubCol = secondSubCollection, let secondSubID = secondSubDocumentID else { return }

        let db = Firestore.firestore()
        
        // Retrieve the specific document representing the second figurine
        let secondFigurineRef = db.collection("figurines").document(mainID).collection(secondSubCol).document(secondSubID)

        secondFigurineRef.getDocument { document, error in
            guard let document = document, document.exists, let data = document.data(), error == nil else { return }

            // Extract second figurine details from Firestore
            let name = data["name"] as? String ?? "Unknown"
            let rawImageUrl = data["imageurl"] as? String ?? data["imageURL"] as? String ?? ""
            let price = data["price"] as? Double ?? 0.0

            self.secondFigurine = (name, self.cleanImageUrl(rawImageUrl) ?? "", price)

            // Update the UI after retrieving the second figurine
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    // Returns the number of items in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Only add SecondCell if data is available
        return figurines.count + (secondFigurine != nil ? 1 : 0)
    }

    // Configures the CollectionView cells based on the index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < figurines.count {
            // Configure regular figurine cells
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FigurineCell", for: indexPath) as! FigurineCell
            cell.configure(with: figurines[indexPath.item])
            return cell
        } else if let secondFigurine = secondFigurine {
            // Configure SecondCell with different figurine details
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SecondCell", for: indexPath) as! SecondCell
            cell.configure(with: secondFigurine)
            return cell
        }
        return UICollectionViewCell() // Failsafe return statement
    }

    // Configures the layout of CollectionView cells for full-screen paging
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    // Cleans and validates a given Firestore image URL
    func cleanImageUrl(_ url: String) -> String? {
        let cleanedURL = url.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "%20")
        return cleanedURL.lowercased().hasPrefix("http") ? cleanedURL : "https://\(cleanedURL)"
    }
}
