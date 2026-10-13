//
//  PerspectiveCorrection.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/11.
//
import SwiftUI
import Vision
import ImageIO


enum Perspective {
    private static let ciContext = CIContext()

    static func correct(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("Could not get CGImage from UIImage")
            return nil
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            print("Document detection failed: \(error)")
            return nil
        }

        guard let document = request.results?.first else {
            print("No document detected")
            return nil
        }

        // CIImage created from cgImage uses the raw CGImage pixel coordinates.
        // Orient it to match the orientation Vision used for detection.
        let orientedImage = CIImage(cgImage: cgImage)
            .oriented(forExifOrientation: Int32(orientation.rawValue))

        let extent = orientedImage.extent

        func ciPoint(from visionPoint: CGPoint) -> CGPoint {
            // Vision normalized coordinates have a bottom-left origin.
            CGPoint(
                x: extent.minX + visionPoint.x * extent.width,
                y: extent.minY + visionPoint.y * extent.height
            )
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = orientedImage
        filter.topLeft = ciPoint(from: document.topLeft)
        filter.topRight = ciPoint(from: document.topRight)
        filter.bottomLeft = ciPoint(from: document.bottomLeft)
        filter.bottomRight = ciPoint(from: document.bottomRight)

        guard let output = filter.outputImage,
              let outputCGImage = ciContext.createCGImage(output, from: output.extent) else {
            print("Could not render corrected image")
            return nil
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
    }
}

private extension CGImagePropertyOrientation {
    
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
            case .up:            self = .up
            case .down:          self = .down
            case .left:          self = .left
            case .right:         self = .right
            case .upMirrored:    self = .upMirrored
            case .downMirrored:  self = .downMirrored
            case .leftMirrored:  self = .leftMirrored
            case .rightMirrored: self = .rightMirrored
            @unknown default:    self = .up
        }
    }
    
}
