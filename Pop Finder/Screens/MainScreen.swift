import UIKit
import FirebaseMLModelDownloader
import TensorFlowLite

class MainScreen: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scanButton: UIButton!
    
    var interpreter: Interpreter?
    let modelName = "PopDetecter"
    var scannedImage: UIImage?
    var detectedResult: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMLModel { _ in }
    }

    // Load ML Model
    func loadMLModel(completion: @escaping (Bool) -> Void) {
        MLModelManager.shared.downloadMLModel { success in
            completion(success)
        }
    }

    // Select Image from Library
    @IBAction func scanImageTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    // Handles the selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            self.scannedImage = selectedImage
        } else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        picker.dismiss(animated: true) {
            self.processImage(self.scannedImage!)
        }
    }

    // Process Image with ML Model
    func processImage(_ image: UIImage) {
        if MLModelManager.shared.interpreter == nil {
            MLModelManager.shared.downloadMLModel { success in
                if success {
                    self.runMLModel(image)
                }
            }
        } else {
            runMLModel(image)
        }
    }

    // Ensure the segue is called after processing
    private func runMLModel(_ image: UIImage) {
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
                self.detectedResult = ImageProcessing.getDetectionResults(outputResults)
                if self.scannedImage != nil {
                    self.performSegue(withIdentifier: "showPhotoView", sender: nil)
                }
            }
        } catch {
            print("Error processing image")
        }
    }

    // Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoView",
           let destinationVC = segue.destination as? PhotoViewController {
            destinationVC.scannedImage = self.scannedImage
            destinationVC.resultText = self.detectedResult
        }
    }
}
