//
//  OCRService.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//

import Vision
import UIKit
import ImageIO


struct OCRService {
    func recognizeJapaneseText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ja-JP"]

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                options: [:]
            )

            try handler.perform([request])

            return (request.results ?? [])
                .compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                .joined(separator: "\n")
        }.value
    }
}

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "The selected image could not be read."
        }
    }
}

extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            .up
        case .down:
            .down
        case .left:
            .left
        case .right:
            .right
        case .upMirrored:
            .upMirrored
        case .downMirrored:
            .downMirrored
        case .leftMirrored:
            .leftMirrored
        case .rightMirrored:
            .rightMirrored
        @unknown default:
            .up
        }
    }
}

