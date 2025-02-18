import UIKit
import FirebaseMLModelDownloader
import TensorFlowLite

class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    var capturedImage: UIImage?
    var interpreter: Interpreter? //TFL Interpreter
    let modelName = "PopDetecter" //Name of my model on Firebase

    override func viewDidLoad() {
        super.viewDidLoad()
        //Displays the image on the app
        if let image = capturedImage {
            imageView.image = image
        }
        //Loads the ML model, ready for image processing
        loadMLModel { [weak self] success in
            guard let self = self else { return }
            if success, let image = self.capturedImage {
                self.processImage(image)
            } else {
                DispatchQueue.main.async {
                    self.resultLabel.text = "Failed to load ML model."
                }
            }
        }
    }
    // Loads ML model from Firebase or local storage if downloaded
    func loadMLModel(completion: @escaping (Bool) -> Void) {
        MLModelManager.shared.downloadMLModel { [weak self] modelPath in
            guard let self = self, let modelPath = modelPath else {
                completion(false)
                return
            }
            do {
                // Initialisatises the TensorFlow interpreteer
                self.interpreter = try Interpreter(modelPath: modelPath)
                try self.interpreter?.allocateTensors()
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    // Processes the given image and converts it into ML data.
    func processImage(_ image: UIImage) {
        guard let interpreter = interpreter else { return }
        // Resizes image to match model input size of 224x224
        let targetSize = CGSize(width: 224, height: 224)
        guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else { return }
        guard let buffer = imageToMLData(image: resizedImage) else { return }
        
        do {
            // TensorFlow model logic
            try interpreter.copy(buffer, toInputAt: 0)
            try interpreter.invoke()
            
            let outputTensor = try interpreter.output(at: 0)
            let outputResults = dataToFloatArray(outputTensor.data)
            // Prints all confidence levels, mainly used for debugging
            print("Confidence Scores for All Figurines:")
            for (index, confidence) in outputResults.enumerated() {
                let figurineName = MLModelManager.shared.figurineNames[index] ?? "Unknown"
                print(" - \(figurineName): \(confidence * 100)%")
            }
            // Update UILabel with the highest confidence result
            DispatchQueue.main.async {
                self.displayDetectionResults(outputResults)
            }

        } catch {
            return
        }
    }
    // Displays the detected figurine name with confidence percentage
    func displayDetectionResults(_ confidenceScores: [Float]) {
        let maxIndex = argmax(confidenceScores)
        let maxConfidence = confidenceScores[maxIndex] * 100
        // If the scanned image has a confidence of below 50% it will display as no clear match, other wise will display the highest confidence score
        if let detectedFigurine = MLModelManager.shared.figurineNames[maxIndex], maxConfidence >= 50 {
            resultLabel.text = "Detected: \(detectedFigurine) (\(maxConfidence.rounded())%)"
        } else {
            resultLabel.text = "No clear match found."
        }
    }
    
    ///Any changes made here may cause the ML scanning to not work. The ML scanning abides by STRICT parameters and so the logic here is very important.
    // Resizes the given UIImage to 224x224 to match the ML model's expected input format
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(targetSize)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    //Converts image to ML-compatible data
    func imageToMLData(image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4 // Picutre must be in RGBA (4 bytes per pixel)
        let bytesPerRow = width * bytesPerPixel

        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Converts data to Float32
        var floatArray = [Float](repeating: 0, count: width * height * 3)
        for i in 0..<(width * height) {
            //RGB data
            floatArray[i * 3] = Float(pixelData[i * 4]) / 255.0
            floatArray[i * 3 + 1] = Float(pixelData[i * 4 + 1]) / 255.0
            floatArray[i * 3 + 2] = Float(pixelData[i * 4 + 2]) / 255.0
        }

        return floatArray.withUnsafeBytes { Data($0) }
    }
    // Converts data to float array
    func dataToFloatArray(_ data: Data) -> [Float] {
        var floatArray = [Float](repeating: 0, count: data.count / MemoryLayout<Float>.size)
        _ = floatArray.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return floatArray
    }
    // Returns the index of the highest value in array
    func argmax(_ array: [Float]) -> Int {
        var maxIndex = 0
        var maxValue = array[0]

        for (index, value) in array.enumerated() where value > maxValue {
            maxValue = value
            maxIndex = index
        }
        return maxIndex
    }
}
