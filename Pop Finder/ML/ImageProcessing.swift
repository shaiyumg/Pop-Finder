import UIKit

class ImageProcessing {
    // Resizes the given UIImage to 224x224 to match the ML model's expected input format
    static func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(targetSize)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    // Converts image to ML-compatible data
    static func imageToMLData(image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
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
            floatArray[i * 3] = Float(pixelData[i * 4]) / 255.0
            floatArray[i * 3 + 1] = Float(pixelData[i * 4 + 1]) / 255.0
            floatArray[i * 3 + 2] = Float(pixelData[i * 4 + 2]) / 255.0
        }

        return floatArray.withUnsafeBytes { Data($0) }
    }

    // Converts data to float array
    static func dataToFloatArray(_ data: Data) -> [Float] {
        var floatArray = [Float](repeating: 0, count: data.count / MemoryLayout<Float>.size)
        _ = floatArray.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return floatArray
    }

    // Returns the index of the highest value in array
    static func argmax(_ array: [Float]) -> Int {
        var maxIndex = 0
        var maxValue = array[0]

        for (index, value) in array.enumerated() where value > maxValue {
            maxValue = value
            maxIndex = index
        }
        return maxIndex
    }
    // Determines the most confident prediction from the ML model output
    static func getDetectionResults(_ confidenceScores: [Float]) -> String {
        let maxIndex = argmax(confidenceScores)
        let maxConfidence = confidenceScores[maxIndex] * 100
        
        if let detectedFigurine = MLModelManager.shared.figurineNames[maxIndex], maxConfidence >= 50 {
            return "Detected: \(detectedFigurine) (\(maxConfidence.rounded())%)"
        } else {
            return "No clear match found."
        }
    }
}
