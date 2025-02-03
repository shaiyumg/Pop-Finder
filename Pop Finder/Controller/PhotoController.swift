import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var capturedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Display the captured image
        if let image = capturedImage {
            imageView.image = image
        }
    }
}
