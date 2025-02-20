import UIKit

class LibraryScreen: UIViewController {
    
    @IBOutlet weak var SoundSeries: UIImageView!
    @IBOutlet weak var SoundButton: UIButton!
    @IBOutlet weak var IORButton: UIButton!
    @IBOutlet weak var IORSeries: UIImageView!
    
    var selectedMainCollection: String?
    var selectedMainDocumentID: String?
    var selectedSubCollection: String?
    var selectedSubDocumentID: String?
    var selectedSecondSubCollection: String?
    var selectedSecondSubDocumentID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Apply rounded corners to images
        [SoundSeries, IORSeries].forEach {
            $0?.layer.cornerRadius = 10
            $0?.clipsToBounds = true
        }
    }

    // Navigate to Sound Series
    @IBAction func soundSeriesTapped() {
        selectedMainCollection = "figurines"
        selectedMainDocumentID = "The Sound Series"
        selectedSubCollection = "The Trust"
        selectedSubDocumentID = "pj7YLUYNYU2fKOfZd5yv"
        selectedSecondSubCollection = "The Serenity"
        selectedSecondSubDocumentID = "hLJupmeFlZFz4e6vr6pP"

        performSegue(withIdentifier: "showSkullPanda", sender: self)
    }

    // Navigate to Image Of Reality Series
    @IBAction func IORButtonTapped() {
        selectedMainCollection = "figurines"
        selectedMainDocumentID = "The Image Of Reality"
        selectedSubCollection = "The Philosophy"
        selectedSubDocumentID = "yer09j8p8CrylQShDknU"
        selectedSecondSubCollection = "The Timelapse"
        selectedSecondSubDocumentID = "M0l9Atg3w25eT70OD0vb"

        performSegue(withIdentifier: "showSkullPanda", sender: self)
    }

    // Prepare for segue and pass all necessary data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSkullPanda",
           let destinationVC = segue.destination as? SkullPandaController,
           let mainID = selectedMainDocumentID,
           let subCol = selectedSubCollection,
           let subID = selectedSubDocumentID {

            destinationVC.mainDocumentID = mainID
            destinationVC.subCollection = subCol
            destinationVC.subDocumentID = subID

            if let secondSubCol = selectedSecondSubCollection, let secondSubID = selectedSecondSubDocumentID {
                destinationVC.secondSubCollection = secondSubCol
                destinationVC.secondSubDocumentID = secondSubID
            }
        }
    }
}
