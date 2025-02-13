import UIKit

class LibraryScreen: UIViewController {
    
    @IBOutlet weak var SoundSeries: UIImageView!
    @IBOutlet weak var SoundButton: UIButton!
    @IBOutlet weak var InkButton: UIButton!
    @IBOutlet weak var InkSeries: UIImageView!
    
    var selectedMainDocumentID: String?
    var selectedSubCollection: String?
    var selectedSubDocumentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply rounded corners to images
        SoundSeries.layer.cornerRadius = 10
        SoundSeries.clipsToBounds = true
        
        InkSeries.layer.cornerRadius = 10
        InkSeries.clipsToBounds = true
    }

    // Navigate to Sound Series
    @IBAction func soundSeriesTapped() {
        selectedMainDocumentID = "NOQ2CtASlU26rXsfft8F"
        selectedSubCollection = "SoundSeries"
        selectedSubDocumentID = "w0PSVz3ALVF4uS6efaBa"
        performSegue(withIdentifier: "showSkullPanda", sender: self)
    }

    // Navigate to Ink Plum Series
    @IBAction func inkButtonTapped() {
        selectedMainDocumentID = "NOQ2CtASlU26rXsfft8F"
        selectedSubCollection = "InkPlumes"
        selectedSubDocumentID = "ZEvl3oj5SDY3AUX1qoHb"
        performSegue(withIdentifier: "showSkullPanda", sender: self)
    }

    // Prepare data before transitioning to SkullPandaController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let mainID = selectedMainDocumentID,
              let subCol = selectedSubCollection,
              let subID = selectedSubDocumentID else {
            return
        }

        if segue.identifier == "showSkullPanda",
           let destinationVC = segue.destination as? SkullPandaController {
            destinationVC.mainDocumentID = mainID
            destinationVC.subCollection = subCol
            destinationVC.subDocumentID = subID
        }
    }
}
