//
//  TranslatorModel.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation
import FoundationModels
import Vision


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
        
        do {
            ocrTextItems = try await ocrService.recognizeJapaneseText(from: image)
            let text = ocrTextItems.reconstructedText()
            japaneseText = text
            guard !text.trim().isEmpty else {
                errorMessage = "No Japanese text was recognized."
                return
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func translate(using session: TranslationSession) async {
        let source = japaneseText.trim()
        guard !source.isEmpty else {
            return
        }
        do {
            let response = try await session.translate(source)
            englishText = response.targetText
        } catch {
            errorMessage = error.localizedDescription
        }
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
    
    //---------------AI-----------------------------
    
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

    func analyzeMenuImage(_ image: CGImage) async -> MenuTranslation? {
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        
        print("Availability: \(model.availability)")
        print("Variant: \(model.variant)")
        
        guard case .available = model.availability else {
            print("Foundation Models unavailable: \(model.availability)")
            return nil
        }
        
        do {
            let session = LanguageModelSession(tools: [OCRTool()])
            let response = try await session.respond(generating: MenuTranslation.self) {
                """
                Read the Japanese text in the attached image labelled “MENU-IMAGE”.
                Use the OCR tool to read the text.
                Translate all Japanese text into natural English, including section titles, category headings, menu item names, and descriptions.
                Organize the translated text into menu sections and individual menu items.
                All section titles must be in English, never Japanese.
                Include descriptions and prices when they are present.
                """
                Attachment(image).label("MENU-IMAGE")
            }
            return response.content
        } catch {
            print("Menu analysis failed: \(error)")
            return nil
        }
    }
    
    func doAiTranslation() async -> MenuTranslation? {
        if let img = selectedImage, let cgimg = img.cgImage {
            let menu = await analyzeMenuImage(cgimg)
            if let menu {
                let translations = makeTranslations(
                    from: menu,
                    ocrItems: ocrTextItems
                )
                translatedText = translations
            }
            return menu
        }
        return nil
    }

}
