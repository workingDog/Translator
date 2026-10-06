//
//  TranslatorModel.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import UIKit
import SwiftUI
import Vision
import Translation
import PhotosUI



@MainActor
@Observable
final class TranslatorModel {
    
    var selectedImage: UIImage?
    var japaneseText = ""
    var englishText = ""
    var isProcessing = false
    var errorMessage: String?

    // Changing this causes the translationTask modifier to receive
    // a new translation configuration.
    var translationConfiguration: TranslationSession.Configuration?

    
    func doRecognition() async {
        if let img = selectedImage {
            await process(image: img)
        }
    }
    
    private func process(image: UIImage) async {
        japaneseText = ""
        englishText = ""
        errorMessage = nil
        isProcessing = true

        do {
            let items = try await OCRService().recognizeJapaneseText(from: image)
            
            for item in items {
                print(String(
                    format: "%.3f %.3f %.3f %.3f  %@",
                    item.boundingBox.minX,
                    item.boundingBox.minY,
                    item.boundingBox.width,
                    item.boundingBox.height,
                    item.text)
                )
            }
            
            let text = items.reconstructedText() // see Utility Array extension

            japaneseText = text

            guard !text.trim().isEmpty else {
                errorMessage = "No Japanese text was recognized."
                isProcessing = false
                return
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func translate(using session: TranslationSession) async {
        isProcessing = true
        let source = japaneseText.trim()
        guard !source.isEmpty else { return }
        do {
            let response = try await session.translate(source)
            englishText = response.targetText
            isProcessing = false
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
        }
    }
}
