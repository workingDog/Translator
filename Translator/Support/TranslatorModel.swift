//
//  TranslatorModel.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation


@MainActor
@Observable
final class TranslatorModel {
    
    var testImage: UIImage?
    var selectedImage: UIImage?
    var japaneseText = ""
    var englishText = ""
    var isProcessing = false
    var errorMessage: String?
    var fontScale: Double = 1.0
    var translationConfiguration: TranslationSession.Configuration?
    var translatedText: [UUID: String] = [:]
    var ocrTextItems: [OCRTextItem] = []
    var menuTranslation: MenuTranslation?
    
    @ObservationIgnored var ocrService = OCRService()
    
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
            ocrTextItems = try await ocrService.recognizeJapaneseText(from: image)
            let text = ocrTextItems.reconstructedText()
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
        guard !source.isEmpty else {
            isProcessing = false
            return
        }
        do {
            let response = try await session.translate(source)
            englishText = response.targetText
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    @MainActor
    func renderTranslatedMenu() -> UIImage {
        guard let image = selectedImage else { return UIImage() }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            for item in ocrTextItems {
                guard let translation = translatedText[item.id], !translation.isEmpty else { continue }
                let box = CGRect(
                    x: item.boundingBox.minX * image.size.width,
                    y: (1 - item.boundingBox.maxY) * image.size.height,
                    width: item.boundingBox.width * image.size.width,
                    height: item.boundingBox.height * image.size.height
                )
                let fontSize = max(box.height * 0.72 * fontScale, 8)
                let font = UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label]
                UIColor.systemBackground.withAlphaComponent(0.92).setFill()
                UIBezierPath(roundedRect: box.insetBy(dx: -4, dy: -2), cornerRadius: 3).fill()
                (translation as NSString).draw(in: box.insetBy(dx: 4, dy: 2), withAttributes: attributes)
            }
        }
    }
    
    func translateOCRItems(using session: TranslationSession) async {
        isProcessing = true
        let requests = ocrTextItems.map {
            TranslationSession.Request(sourceText: $0.text)
        }
        do {
            let responses = try await session.translations(from: requests)
            var translations: [UUID: String] = [:]
            for (item, response) in zip(ocrTextItems, responses) {
                translations[item.id] = response.targetText
            }
            translatedText = translations
        } catch {
            translatedText = Dictionary(uniqueKeysWithValues: ocrTextItems.map { ($0.id, $0.text) })
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    @MainActor
    func saveTranslatedMenu(title: String, modelContext: ModelContext) {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.9) else { return }
        
        let savedOCRData = SavedOCRData(
            items: ocrTextItems,
            translations: translatedText
        )
        
        guard let ocrData = try? JSONEncoder().encode(savedOCRData) else { return }
        let aiData = menuTranslation.flatMap { try? JSONEncoder().encode($0) }
        
        let savedMenu = TranslatedMenu(
            title: title,
            imageData: imageData,
            ocrData: ocrData,
            aiData: aiData
        )
        
        modelContext.insert(savedMenu)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save translated menu: \(error)")
        }
    }
    
    func makeTranslations(from menu: MenuTranslation, ocrItems: [OCRTextItem]) -> [UUID: String] {
        menuTranslation = menu
        var translations: [UUID: String] = [:]
        
        for section in menu.sections {
            for menuItem in section.items {
                if let ocrItem = ocrItems.first(where: { $0.text == menuItem.japanese }) {
                    translations[ocrItem.id] = menuItem.english
                }
            }
        }
        return translations
    }

}
