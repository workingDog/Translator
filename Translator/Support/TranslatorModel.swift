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
    
    var selectedImageItem: ImageItem?
    
    var japaneseText = ""
    var englishText = ""
    var isProcessing = false
    var errorMessage: String?
    var fontScale: Double = 1.0
    var spacing: Double = 0.0
    
    var translationConfiguration: TranslationSession.Configuration?
    
    var ocrTextItems: [OCRTextItem] = []
    
    var loanwords: [String: String] = [:]
    
    @ObservationIgnored var ocrService = OCRService()
    
    
    init() {
        loadMenuData()
    }
    
    func resetTranslation() {
        japaneseText = ""
        englishText = ""
        ocrTextItems = []
        errorMessage = nil
        isProcessing = false
        translationConfiguration = nil
        selectedImageItem = nil
    }
    
    func doRecognition() async {
        if let imgItem = selectedImageItem {
            await process(image: imgItem.getImage())
        }
    }
    
    private func process(image: UIImage) async {
        japaneseText = ""
        englishText = ""
        errorMessage = nil
        
        do {
            ocrTextItems = try await ocrService.recognizeJapaneseText(from: image)
            japaneseText = ocrTextItems.reconstructedText()
            guard !japaneseText.trim().isEmpty else {
                errorMessage = "No Japanese text was recognized."
                return
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // experiment
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
        
        guard let imgItem = selectedImageItem else { return UIImage() }
        
        let image = imgItem.getImage()
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            for item in ocrTextItems {
                guard !item.text.isEmpty else { continue }
                
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
                
                (item.text as NSString).draw(in: box.insetBy(dx: 4, dy: 2), withAttributes: attributes)
            }
            
        }
    }
    
    func translateOCRItems(using session: TranslationSession) async {
        var theItems: [OCRTextItem] = []
        
        let requests = ocrTextItems.map {
            TranslationSession.Request(sourceText: $0.text)
        }
        do {
            let responses = try await session.translations(from: requests)
            
            for (item, response) in zip(ocrTextItems, responses) {
                theItems.append(
                    OCRTextItem(
                        id: item.id,
                        text: item.text,
                        engText: response.targetText,
                        boundingBox: item.boundingBox)
                )
            }
            
            ocrTextItems = theItems
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func saveTranslatedMenu(title: String, menuid: UUID, modelContext: ModelContext) {
        guard let imgItem = selectedImageItem else { return }
        guard let imageData = imgItem.getImage().jpegData(compressionQuality: 0.9) else { return }
        
        let savedOCRData = SavedOCRData(items: ocrTextItems)
        
        guard let ocrData = try? JSONEncoder().encode(savedOCRData) else { return }
        
        let descriptor = FetchDescriptor<TranslatedMenu>(
            predicate: #Predicate { $0.menuid == menuid })
        
        do {
            if let savedMenu = try modelContext.fetch(descriptor).first {
                savedMenu.title = title
                savedMenu.imageData = imageData
                savedMenu.ocrData = ocrData
                savedMenu.createdAt = .now
            } else {
                let savedMenu = TranslatedMenu(
                    menuid: menuid,
                    title: title,
                    imageData: imageData,
                    ocrData: ocrData
                )
                modelContext.insert(savedMenu)
            }
            try modelContext.save()
        } catch {
            print("Failed to save translated menu: \(error)")
        }
    }
    
    //---------------katakana-----------------------------
/*
    func loadLoanwords() {
        guard let url = Bundle.main.url(forResource: "menukata", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([KataItem].self, from: data)
            loanwords = Dictionary(entries.map { ($0.japanese, $0.english) }, uniquingKeysWith: { first, _ in first })
        } catch {
            print(error)
        }
    }
    
    func getKatakanaWords(_ text: String) -> [String: String] {
        Dictionary(
            text.katakanaWords.compactMap { word in
                loanwords[word].map { (word, $0) }
            },
            uniquingKeysWith: { first, _ in first }
        )
    }
    
    func applyMenuDictionary() {
        ocrTextItems = ocrTextItems.map { item in
            guard let translation = loanwords[item.text] else {
                return item
            }
            var updatedItem = item
            updatedItem.engText = translation
            return updatedItem
        }
    }
    
    func loadMenuWords1() throws -> [MenuWord] {
        let words = try loadJMDict().words
        var results: [MenuWord] = []
        
        for word in words {
            let katakana = word.kana.map(\.text).filter { $0.range(of: "^[ァ-ヿー]+$", options: .regularExpression) != nil }
            
            guard !katakana.isEmpty else { continue }
            
            for sense in word.sense {
                let english = sense.gloss.filter { $0.lang == "eng" }.map(\.text)
                guard !english.isEmpty else { continue }
                for spelling in katakana {
                    results.append(MenuWord(katakana: spelling, english: english.joined(separator: "; ") ) )
                }
            }
        }
        
        return results
    }
    
    func loadJMDict() throws -> JMDict {
        let url = Bundle.main.url(forResource: "jmdict-eng-3.6.2", withExtension: "json")!
        return try JSONDecoder().decode(JMDict.self, from: Data(contentsOf: url))
    }
    
    func saveMenuWords() throws {
        let results = try loadMenuWords1()
        let data = try JSONEncoder().encode(results)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "menuWords.json")
        try data.write(to: url, options: .atomic)
        print("Saved \(results.count) words to \(url.path)")
    }
    */
    
    //--------------------------------------------
    
    func loadMenuData() {
        loadMenuWords()
        loadMenuKata()
        loadAltData()
        print("---> loanwords: \(loanwords.count)")
    }
    
    func loadMenuKata() {
        guard let url = Bundle.main.url(forResource: "menukata", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([KataItem].self, from: data)
            print("---> loadMenuKata: \(entries.count)")
            for entry in entries {
                loanwords[entry.japanese.trim()] = loanwords[entry.japanese] ?? entry.english.trim()
            }
        } catch {
            print(error)
        }
    }

    func loadMenuWords() {
        do {
            let url = Bundle.main.url(forResource: "menuWords", withExtension: "json")!
            let results = try JSONDecoder().decode([MenuWord].self, from: Data(contentsOf: url))
            print("---> loadMenuWords: \(results.count)")
            loanwords = Dictionary(results.map {
                // pick only the first english word
                let theEnglishWord = $0.english.components(separatedBy: ";").first ?? $0.english
                return ($0.katakana.trim(), theEnglishWord.trim())
            }, uniquingKeysWith: { first, _ in first })
        } catch {
            print(error)
        }
    }

    func loadAltData() {
        do {
            let url = Bundle.main.url(forResource: "AltData", withExtension: "json")!
            let entries = try JSONDecoder().decode([KataItem].self, from: Data(contentsOf: url))
            print("---> loadAltData: \(entries.count)")
            for entry in entries {
                loanwords[entry.japanese.trim()] = loanwords[entry.japanese] ?? entry.english.trim()
            }
        } catch {
            print(error)
        }
    }

    func applyMenuWords() {
        ocrTextItems = ocrTextItems.map { item in
            guard let translation = loanwords[item.text] else {
                return item
            }
            var updatedItem = item
            
            print("---> text: \(item.text) english1: \(item.engText) english2: \(translation) ")
            
            updatedItem.engText = translation
            return updatedItem
        }
    }
    
    //---------------AI-----------------------------
    
    func analyzeMenuOCR1(_ items: [NewOCRTextItem]) async -> [NewOCRTextItem]? {
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        
        guard case .available = model.availability else { return nil }
        
        do {
            let session = LanguageModelSession {
"""
You are an expert Japanese-to-English translator specializing in Japanese restaurant menus.
Your task is to improve existing English translations using the original Japanese text as the authoritative source.
For each entry:

* Correct mistranslations and unnatural English.
* Use natural, concise English appropriate for a restaurant menu.
* Prefer established English names for Japanese dishes, ingredients, and cooking methods.
* Use the existing English translation as a starting point, not as an authoritative translation.
* Use the surrounding entries to understand the menu context when helpful.
* Preserve the original meaning, including ingredients, preparation methods, quantities, and distinctions between dishes.
* Do not add ingredients, descriptions, or details that are not supported by the Japanese.
* Preserve prices, numbers, and other factual information exactly as they are.
* Translate headings, labels, and short phrases naturally.
* If the existing English is already accurate and appropriate, leave it unchanged.
* If the Japanese is ambiguous, prefer a conservative translation rather than guessing.

Return one improved English translation for each input entry in the "english" field, in exactly the same order. Do not modify any other field in the input items, only the "english" field.
"""
            }

            let response = try await session.respond(generating: [NewOCRTextItem].self) {
                "Improve the English translations of these Japanese restaurant menu entries."
                "For each entry, use 'text' as the authoritative Japanese source and 'engText' as the existing English translation."
                "Return the improved translation in 'english'. Preserve 'id', 'text', and 'engText' exactly."
                "Return exactly \(items.count) entries in the same order."
                "\(items)"
            }

            return response.content

        } catch {
            print("Menu analysis failed: \(error)")
            return nil
        }
    }
  
    func doAiTranslation1() async -> [NewOCRTextItem]? {
        print("---> doAiTranslation ocrTextItems: \(ocrTextItems.count)\n")
        var allItems: [NewOCRTextItem] = []
        let batchSize = 20
        
        var count = 0
        
        let testSet = Array(ocrTextItems.prefix(40))
        
        for startIndex in stride(from: 0, to: testSet.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, testSet.count)
            let batch = testSet[startIndex..<endIndex].map { NewOCRTextItem(item: $0) }
            if let translatedItems = await analyzeMenuOCR(Array(batch)) {
                allItems.append(contentsOf: translatedItems)
            }
            count += batchSize
            print("---> batch: \(count)\n")
        }
        return allItems.isEmpty ? nil : allItems
    }
    
    
    
    func analyzeMenuOCR(_ items: [NewOCRTextItem]) async -> [NewOCRTextItem]? {
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
        guard case .available = model.availability else { return nil }
        do {
            let session = LanguageModelSession {
                """
                You are an expert in Japanese food terminology and Japanese-to-English translation.
                Improve the English translations of Japanese restaurant menu entries containing katakana.
                The Japanese 'text' is the authoritative source. The existing 'engText' is a machine translation that may be incorrect.
                Identify katakana loanwords and determine their intended meaning in the context of Japanese cuisine.
                Prefer natural English food names over literal transliterations.
                Recognize Japanese culinary terms whose meanings differ from their literal translations.
                Do not invent ingredients or preparation methods.
                Preserve 'id', 'text', and 'engText' exactly.
                Return the corrected translation in 'english'.
                """
            }
            let response = try await session.respond(generating: [NewOCRTextItem].self) {
                "Review these Japanese restaurant menu entries and improve their English translations."
                "Return exactly \(items.count) entries in the same order."
                "\(items)"
            }
            return response.content
        } catch {
            print("Menu analysis failed: \(error)")
            return nil
        }
    }
    
    func doAiTranslation() async -> [NewOCRTextItem]? {
        let items = ocrTextItems.filter { !$0.text.katakanaWords.isEmpty }
        
        print("---> doAiTranslation() items: \(items.count)")
        
        guard !items.isEmpty else { return nil }
        
        var allItems: [NewOCRTextItem] = []
        
        let batchSize = 20
        
        for startIndex in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, items.count)
            let batch = items[startIndex..<endIndex].map { NewOCRTextItem(item: $0) }
            
            if let translatedItems = await analyzeMenuOCR(Array(batch)) {
                allItems.append(contentsOf: translatedItems)
            }
            
        }

        return allItems.isEmpty ? nil : allItems
    }
    
}

/*
 
 
 //  ポーニマメフク Poni Mamefuku
 
 func doAiTranslation2() async -> [NewOCRTextItem]? {
     print("---> doAiTranslation ocrTextItems: \(ocrTextItems.count)\n")
     
     var newItems: [NewOCRTextItem] = []
     
     let testSet = ocrTextItems
     
     for item in ocrTextItems {
       //  print("---> item: \(item.text) \(item.engText)")
         newItems.append(NewOCRTextItem(item: item))
     }
     print()
     
     if !newItems.isEmpty {
         return await analyzeMenuOCR(newItems)
     }
     return nil
 }
 
 
 func analyzeMenuOCR(_ items: [OCRTextItem]) async -> MenuTranslation? {
     let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
     
     guard case .available = model.availability else { return nil }
     
     do {
         let session = LanguageModelSession {
"""
You are an expert Japanese menu translator.
Translate the supplied Japanese OCR text into concise, natural English.
Preserve every identifiable menu section, item, description, and price.
Translate all headings into English.
Never invent or omit identifiable menu items or prices.
Use the bounding boxes to understand the reading order and group items into sections.
Keep descriptions and prices separate from item names.
"""
         }
         
         let ocrText = items.map {
             "Text: \($0.text), Bounding box: x=\($0.boundingBox.origin.x), y=\($0.boundingBox.origin.y), width=\($0.boundingBox.width), height=\($0.boundingBox.height)"
         }.joined(separator: "\n")
         
         let response = try await session.respond(generating: MenuTranslation.self) {
             "Translate the following Japanese menu OCR results into English. Preserve all sections and items:\n\(ocrText)"
         }
         
         return response.content
         
     } catch {
         print("Menu analysis failed: \(error)")
         return nil
     }
 }
 
 func doAiTranslation() async -> MenuTranslation? {
     print("---> doAiTranslation ocrTextItems: \(ocrTextItems.count)\n")
     
     let testSet = Array(ocrTextItems.prefix(21))
     
     for item in testSet {
         print("---> item: \(item.text) \(item.engText)")
     }
     print()
     
     if !testSet.isEmpty {
         return await analyzeMenuOCR(testSet)
     }
     return nil
 }
 
 */








/*
 func analyzeMenuImage(_ image: CGImage) async -> MenuTranslation? {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 print("Availability: \(model.availability)")
 print("Variant: \(model.variant)")
 
 guard case .available = model.availability else {
 print("Foundation Models unavailable: \(model.availability)")
 return nil
 }
 
 do {
 let session = LanguageModelSession(tools: [OCRTool()]) {
 """
 You are an expert Japanese menu translator.
 Use the OCR tool to read the supplied image.
 Translate Japanese into concise, natural English.
 Preserve all identifiable menu sections, items, descriptions, and prices.
 Translate all headings into English.
 Never invent or omit identifiable menu items or prices.
 Keep descriptions and prices separate from item names, and do not include them in the menu items.
 Minimize unnecessary wording in the output.
 Keep the structured response as concise as possible.
 """
 }
 let response = try await session.respond(generating: MenuTranslation.self) {
 """
 Translate the menu in this image "MENU-IMAGE" into English.
 Prioritize completeness and concise output.
 Return the results using MenuTranslation.
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
 if let selectedImage {
 let resizedImage = selectedImage.resizedToMaximumDimension(2500)
 if let cgimg = resizedImage.cgImage {
 let menu = await analyzeMenuImage(cgimg)
 return menu
 }
 }
 return nil
 }
 
 //---------------experiment-----------------------------
 
 func analyzeMenuImage3(_ image: CGImage, depth: Int = 0) async -> MenuTranslation? {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 guard case .available = model.availability else {
 print("Foundation Models unavailable: \(model.availability)")
 return nil
 }
 if let result = await translateMenuPart(image) {
 return result
 }
 guard depth < 5, let parts = splitImage(image) else {
 print("Unable to translate image at split depth \(depth).")
 return nil
 }
 guard let first = await analyzeMenuImage3(parts[0], depth: depth + 1) else { return nil }
 guard let second = await analyzeMenuImage3(parts[1], depth: depth + 1) else { return nil }
 return combineTranslations(first, second)
 }
 
 func translateMenuPart(_ image: CGImage) async -> MenuTranslation? {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 guard case .available = model.availability else {
 print("Foundation Models unavailable: \(model.availability)")
 return nil
 }
 
 do {
 let session = LanguageModelSession(tools: [OCRTool()]) {
 """
 You are an expert Japanese menu translator.
 Use the OCR tool to read the supplied image.
 Translate Japanese into concise, natural English.
 Preserve all identifiable menu sections, items, descriptions, and prices.
 Translate all headings into English.
 Never invent or omit identifiable menu items or prices.
 Keep descriptions and prices separate from item names.
 Minimize unnecessary wording in the output.
 Keep the structured response as concise as possible.
 """
 }
 let response = try await session.respond(generating: MenuTranslation.self) {
 """
 Translate the menu in this image "MENU-IMAGE" into English.
 Prioritize completeness and concise output.
 Return the results using MenuTranslation.
 """
 Attachment(image).label("MENU-IMAGE")
 }
 
 return response.content
 
 } catch {
 print("Menu analysis failed: \(error)")
 return nil
 }
 
 }
 
 func splitImage(_ image: CGImage) -> [CGImage]? {
 
 let width = image.width
 let height = image.height
 let overlap = min(height / 20, 100)
 let middle = height / 2
 let topHeight = min(height, middle + overlap)
 let bottomY = max(0, middle - overlap)
 let bottomHeight = height - bottomY
 
 guard let top = image.cropping(to: CGRect(x: 0, y: 0, width: width, height: topHeight)),
 let bottom = image.cropping(to: CGRect(x: 0, y: bottomY, width: width, height: bottomHeight)) else {
 return nil
 }
 
 return [top, bottom]
 }
 
 func combineTranslations(_ first: MenuTranslation, _ second: MenuTranslation) -> MenuTranslation {
 var combined = first
 for secondSection in second.sections {
 if let index = combined.sections.firstIndex(where: {
 $0.title.localizedCaseInsensitiveCompare(secondSection.title) == .orderedSame
 }) {
 for item in secondSection.items {
 if !combined.sections[index].items.contains(where: {
 $0.japanese == item.japanese
 }) {
 combined.sections[index].items.append(item)
 }
 }
 } else {
 var newSection = secondSection
 newSection.items.removeAll { item in
 combined.sections.contains { section in
 section.items.contains { $0.japanese == item.japanese }
 }
 }
 if !newSection.items.isEmpty {
 combined.sections.append(newSection)
 }
 }
 }
 return combined
 }
 
 func countMenuInputTokens() async {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 let instructions = Instructions {
 """
 You are an expert Japanese-to-English menu translator.
 Accurately translate Japanese restaurant menus into natural,
 clear English while preserving the meaning of the original text.
 Use the OCR tool to recognise the Japanese text in the supplied image.
 Never invent text, menu items, descriptions, or prices.
 Translate all section titles, category headings, item names,
 and descriptions into English.
 All section titles and category headings must be in English.
 Include descriptions and prices when present, but do not include them in menu items.
 Organise the results into the appropriate menu sections and items.
 """
 }
 
 let prompt = Prompt {
 """
 Analyse the attached image labelled "MENU-IMAGE".
 Read the Japanese text using the OCR tool and translate the complete
 menu into English.
 Include all identifiable menu sections, individual items,
 descriptions, and prices.
 Return the results using the MenuTranslation structure.
 """
 }
 
 do {
 let instructionTokens = try await model.tokenCount(for: instructions)
 let promptTokens = try await model.tokenCount(for: prompt)
 let toolTokens = try await model.tokenCount(for: [OCRTool()])
 let schemaTokens = try await model.tokenCount(for: MenuTranslation.generationSchema)
 
 print("Instructions: \(instructionTokens)")
 print("Prompt: \(promptTokens)")
 print("OCRTool: \(toolTokens)")
 print("MenuTranslation schema: \(schemaTokens)")
 print("Subtotal (excluding image and other overhead): \(instructionTokens + promptTokens + toolTokens + schemaTokens)")
 print("Model context size: \(model.contextSize)")
 } catch {
 print("Token counting failed: \(error)")
 }
 
 }
 
 //----------------------------------------------------------
 
 func analyzeMenuOCR(_ items: [OCRTextItem]) async {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 guard case .available = model.availability else { return }
 
 do {
 let session = LanguageModelSession {
 """
 You are an expert Japanese menu translator.
 Translate the supplied Japanese OCR text into concise, natural English.
 Preserve every identifiable menu section, item, description, and price.
 Translate all headings into English.
 Never invent or omit identifiable menu items or prices.
 Use the bounding boxes to understand the reading order and group items into sections.
 Keep descriptions and prices separate from item names.
 """
 }
 
 let ocrText = items.map {
 "Text: \($0.text), Bounding box: x=\($0.boundingBox.origin.x), y=\($0.boundingBox.origin.y), width=\($0.boundingBox.width), height=\($0.boundingBox.height)"
 }.joined(separator: "\n")
 
 let response = try await session.respond(generating: MenuTranslation.self) {
 "Translate the following Japanese menu OCR results into English. Preserve all sections and items:\n\(ocrText)"
 }
 
 //         return response.content
 
 } catch {
 print("Menu analysis failed: \(error)")
 }
 }
 
 func doAiTranslation(items: [OCRTextItem]) async -> MenuTranslation? {
 if !items.isEmpty {
 await analyzeMenuOCR(items)
 }
 return nil
 }
 
 func doAiTranslation8() async -> MenuTranslation? {
 print("---> doAiTranslation8 ocrTextItems: \(ocrTextItems.count)\n")
 
 for item in ocrTextItems {
 print("---> item: \(item.text) \(item.engText)")
 }
 print()
 
 return await doAiTranslation(items: ocrTextItems)
 }
 
 //----------------------------------------------------------
 
 func doAiTranslation9() async -> MenuTranslation? {
 if let selectedImage {
 let resizedImage = selectedImage.resizedToMaximumDimension(2500)
 if let cgimg = resizedImage.cgImage {
 let menu = await analyzeMenuImage9(cgimg)
 return menu
 }
 }
 return nil
 }
 
 func analyzeMenuImage9(_ image: CGImage) async -> MenuTranslation? {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 print("Availability: \(model.availability)")
 print("Variant: \(model.variant)")
 
 guard case .available = model.availability else {
 print("Foundation Models unavailable: \(model.availability)")
 return nil
 }
 
 do {
 let session = LanguageModelSession(tools: [OCRTool()]) {
 """
 You are an expert Japanese menu translator.
 Use the OCR tool to read the supplied image.
 Translate Japanese into concise, natural English.
 Preserve all identifiable menu sections, items, descriptions, and prices.
 Translate all headings into English.
 Never invent or omit identifiable menu items or prices.
 Keep descriptions and prices separate from item names, and do not include them in the menu items.
 Minimize unnecessary wording in the output.
 Keep the structured response as concise as possible.
 """
 }
 let response = try await session.respond(generating: MenuTranslation.self) {
 """
 Translate the menu in this image "MENU-IMAGE" into English.
 Prioritize completeness and concise output.
 Return the results using MenuTranslation.
 """
 Attachment(image).label("MENU-IMAGE")
 }
 
 return response.content
 
 } catch {
 print("Menu analysis failed: \(error)")
 return nil
 }
 
 }
 
 }
 
 */





/*
 
 
 
 
 
 
 
 
 
 
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
 
 
 
 
 
 func analyzeMenuImage(_ image: CGImage) async -> MenuTranslation? {
 let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
 
 print("Availability: \(model.availability)")
 print("Variant: \(model.variant)")
 
 guard case .available = model.availability else {
 print("Foundation Models unavailable: \(model.availability)")
 return nil
 }
 
 do {
 let session = LanguageModelSession(tools: [OCRTool()]) {
 """
 You are an expert Japanese-to-English menu translator.
 
 Accurately translate Japanese restaurant menus into natural,
 clear English while preserving the meaning of the original text.
 
 Use the OCR tool to recognise the Japanese text in the supplied image.
 Never invent text, menu items, descriptions, or prices.
 Translate all section titles, category headings, item names,
 and descriptions into English.
 All section titles and category headings must be in English.
 Include descriptions and prices when they are present, but do not include them in the menu items.
 Organise the results into the appropriate menu sections and items.
 """
 }
 
 let response = try await session.respond(generating: MenuTranslation.self) {
 """
 Analyse the attached image labelled "MENU-IMAGE".
 
 Read the Japanese text using the OCR tool and translate the complete
 menu into English.
 
 Include all identifiable menu sections, individual items,
 descriptions, and prices.
 
 Return the results using the MenuTranslation structure.
 """
 Attachment(image).label("MENU-IMAGE")
 }
 
 return response.content
 
 } catch {
 print("Menu analysis failed: \(error)")
 return nil
 }
 
 }
 
 
 */
