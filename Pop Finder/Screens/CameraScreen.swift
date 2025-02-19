import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput: AVCapturePhotoOutput?
    var capturedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLiveCameraFeed()
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    }

    // Set up the camera feed
    func setupLiveCameraFeed() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoDeviceInput: AVCaptureDeviceInput
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Failed to create video device input: \(error)")
            return
        }
        
        if captureSession?.canAddInput(videoDeviceInput) ?? false {
            captureSession?.addInput(videoDeviceInput)
        } else {
            print("Failed to add input to session")
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession?.canAddOutput(photoOutput!) ?? false {
            captureSession?.addOutput(photoOutput!)
        } else {
            print("Failed to add photo output")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = cameraView.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer!)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    // Capture image when button is pressed
    @IBAction func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(error!)")
            return
        }

        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            capturedImage = image
            
            // Navigate to the next view controller to display the image
            performSegue(withIdentifier: "showPhoto", sender: self)
        }
    }
    
    // Prepare the photo for the next view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            if let photoVC = segue.destination as? PhotoViewController {
                photoVC.scannedImage = capturedImage
            }
        }
    }
}
