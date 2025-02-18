import UIKit
import FirebaseMLModelDownloader
import TensorFlowLite

class PhotoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    var capturedImage: UIImage?
    var interpreter: Interpreter? // TensorFlow Lite Interpreter
    let modelName = "PopDetecter" // Your Firebase ML Model Name

    override func viewDidLoad() {
        super.viewDidLoad()

        // Display the captured image
        if let image = capturedImage {
            imageView.image = image
            processImage(image)
        }

        // Load ML Model
        loadMLModel()
    }

    // Load ML Model from Firebase
    func loadMLModel() {
        MLModelManager.shared.downloadMLModel { [weak self] modelPath in
            guard let self = self, let modelPath = modelPath else {
                print("ML Model download failed or path is nil")
                return
            }
            do {
                self.interpreter = try Interpreter(modelPath: modelPath)
                try self.interpreter?.allocateTensors()
                print("ML Model Loaded Successfully!")
            } catch {
                print("Error loading ML model: \(error.localizedDescription)")
            }
        }
    }

    // Process Image & Run ML Model Inference
    func processImage(_ image: UIImage) {
        guard let interpreter = interpreter else {
            print("ML Model is not ready yet!")
            return
        }

        // Resize the image manually
        let targetSize = CGSize(width: 224, height: 224) // Change if your model requires a different size
        guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else {
            print("Failed to resize image")
            return
        }

        // Convert UIImage to Data
        guard let buffer = imageToMLData(image: resizedImage) else {
            print("Failed to convert image to ML-compatible buffer")
            return
        }

        // Run inference
        do {
            try interpreter.copy(buffer, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let outputResults = dataToFloatArray(outputTensor.data)

            // Get the classification result
            let detectedClass = argmax(outputResults)
            let confidence = outputResults[detectedClass]

            // Retrieve figurine name from MLModelManager
            let figurineName = MLModelManager.shared.figurineNames[detectedClass] ?? "Unknown Figurine"

            print("Detected: \(figurineName) (Class: \(detectedClass), Confidence: \(confidence))")

            // Display result on UI
            DispatchQueue.main.async {
                self.resultLabel.text = "Detected: \(figurineName) (\(Int(confidence * 100))% confidence)"
            }

        } catch {
            print("Error during inference: \(error.localizedDescription)")
        }
    }

    // Manually Resize UIImage Without Extension
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    // Convert UIImage to Data for ML Processing
    func imageToMLData(image: UIImage) -> Data? {
        guard let pixelData = image.cgImage?.dataProvider?.data else { return nil }
        return pixelData as Data
    }

    // Convert Data to Float Array for ML Model
    func dataToFloatArray(_ data: Data) -> [Float] {
        let floatCount = data.count / MemoryLayout<Float>.stride
        var floatArray = [Float](repeating: 0, count: floatCount)
        _ = floatArray.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return floatArray
    }

    // Find Index of Maximum Confidence Value
    func argmax(_ array: [Float]) -> Int {
        guard let maxValue = array.max() else { return -1 }
        return array.firstIndex(of: maxValue) ?? -1
    }
}
