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

    func recognizeJapaneseText(from image: UIImage) async throws -> [OCRTextItem] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await Task.detached(priority: .userInitiated) {
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ja-JP"]
            
            let handler = await VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                options: [:]
            )

            try handler.perform([request])

            return (request.results ?? []).compactMap { observation -> OCRTextItem? in
                guard let text = observation.topCandidates(1).first?.string else {
                    return nil
                }

                return OCRTextItem(text: text, boundingBox: observation.boundingBox)
            }
        }.value
    }

}

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: "The selected image could not be read."
        }
    }
}

