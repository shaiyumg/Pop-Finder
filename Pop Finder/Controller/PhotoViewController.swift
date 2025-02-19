import UIKit
import FirebaseMLModelDownloader
import TensorFlowLite

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    var scannedImage: UIImage?
    var resultText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = scannedImage {
            imageView.image = image
        }

        if let result = resultText {
            resultLabel.text = result
        } else if MLModelManager.shared.interpreter != nil {
            if let image = scannedImage {
                processImage(image)
            }
        } else {
            MLModelManager.shared.downloadMLModel { success in
                if success, let image = self.scannedImage {
                    self.processImage(image)
                } else {
                    self.resultLabel.text = "Failed to load ML model."
                }
            }
        }
    }

    // Process Image with ML Model
    func processImage(_ image: UIImage) {
        guard let interpreter = MLModelManager.shared.interpreter else { return }

        let targetSize = CGSize(width: 224, height: 224)
        guard let resizedImage = ImageProcessing.resizeImage(image: image, targetSize: targetSize) else { return }
        guard let buffer = ImageProcessing.imageToMLData(image: resizedImage) else { return }

        do {
            try interpreter.copy(buffer, toInputAt: 0)
            try interpreter.invoke()

            let outputTensor = try interpreter.output(at: 0)
            let outputResults = ImageProcessing.dataToFloatArray(outputTensor.data)

            DispatchQueue.main.async {
                self.resultText = ImageProcessing.getDetectionResults(outputResults)
                self.resultLabel.text = self.resultText
            }
        } catch {
            print("Error processing image")
        }
    }
}
