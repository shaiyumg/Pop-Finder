import FirebaseMLModelDownloader
import Foundation
import TensorFlowLite

class MLModelManager {
    static let shared = MLModelManager()
    
    let figurineNames: [Int: String] = [
        0: "The Serenity",
        1: "The Philosophy",
        2: "The Trust",
        3: "The Timelapse"
    ]
    
    var interpreter: Interpreter? // Store the interpreter globally

    private init() {}

    func downloadMLModel(completion: @escaping (Bool) -> Void) {
        let downloadConditions = ModelDownloadConditions(allowsCellularAccess: false)
        
        ModelDownloader.modelDownloader()
            .getModel(name: "PopDetecter",
                      downloadType: .latestModel,
                      conditions: downloadConditions,
                      progressHandler: { progress in
                          let percentage = Int(progress * 100)
                          DispatchQueue.main.async {
                              NotificationCenter.default.post(name: .MLModelProgress, object: nil, userInfo: ["progress": percentage])
                          }
                      }) { result in
                switch result {
                case let .success(model):
                    print("Model downloaded successfully at: \(model.path)")
                    
                    do {
                        self.interpreter = try Interpreter(modelPath: model.path)
                        try self.interpreter?.allocateTensors()
                        completion(true) // Notify that the model is ready
                    } catch {
                        print("Failed to initialize TensorFlow interpreter: \(error)")
                        completion(false)
                    }
                    
                case let .failure(error):
                    print("Model download failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
    }
}

// Custom notification for ML model progress updates in Profile Screen when downloading
extension Notification.Name {
    static let MLModelProgress = Notification.Name("MLModelProgress")
}
