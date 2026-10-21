//
//  SwiftDataModels.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData
import FoundationModels
import Vision



@MainActor
@Observable
final class ImageItem: Identifiable {
    let id = UUID()
    
    var uimage: UIImage
    var corectedImg: UIImage
    
    var isCorrected = false {
        didSet {
            guard isCorrected, !oldValue else { return }
            corectedImg = Perspective.correct(uimage) ?? UIImage()
        }
    }

    var isRotated = false {
        didSet {
            guard isRotated != oldValue else { return }
            if isCorrected {
                corectedImg = corectedImg.rotated(by: -90)
            } else {
                uimage = uimage.rotated(by: -90)
            }
        }
    }
    
    init(uimage: UIImage, corectedImg: UIImage = UIImage()) {
        self.uimage = uimage
        self.corectedImg = corectedImg
    }

    var imgData: Data? {
        if isCorrected {
            let resized = corectedImg.resizedToFitWidth(1280)
            return resized.jpegData(compressionQuality: 0.9)
        }
        let resized = uimage.resizedToFitWidth(1280)
        return resized.jpegData(compressionQuality: 0.9)
    }
    
    func getImage() -> UIImage {
        isCorrected ? corectedImg : uimage
    }

}

@Model
final class TranslatedMenu {
    var menuid: UUID
    
    var title: String
    var imageData: Data
    var ocrData: Data?
    var aiData: Data?
    var createdAt: Date

    init(menuid: UUID, title: String, imageData: Data, ocrData: Data, aiData: Data? = nil) {
        self.menuid = menuid
        self.title = title
        self.imageData = imageData
        self.ocrData = ocrData
        self.aiData = aiData
        self.createdAt = .now
    }

}

nonisolated struct OCRTextItem: Identifiable, Codable {
    let id: UUID
    var jaText: String
    var engText: String
    var boundingBox: CGRect
    
    init(id: UUID = UUID(), jaText: String, engText: String, boundingBox: CGRect) {
        self.id = id
        self.jaText = jaText
        self.engText = engText
        self.boundingBox = boundingBox
    }
}

struct SavedOCRData: Codable {
    let items: [OCRTextItem]
}

struct SavedAiData: Codable {
    let items: [MenuItem]
}

@Generable
struct MenuTranslation: Codable {
    var sections: [MenuSection]
}

@Generable
struct MenuSection: Codable {
    var title: String
    var items: [MenuItem]
}

@Generable
struct MenuItem: Identifiable, Codable {
    let id = UUID()
    
    var section: String     // <--- section title in English
    var japanese: String    // <--- original Japanese
    var english: String     // <--- translated English
    var price: String?      // <--- price of the item if available
    var order: Int?         // <--- order in the list if need be
    
    init(section: String, japanese: String, english: String, price: String?, order: Int?) {
        self.section = section
        self.japanese = japanese
        self.english = english
        self.price = price
        self.order = order
    }
    
    init(ai: AIMenuItem, english: String) {
        self.section = ai.section
        self.japanese = ai.japanese
        self.english = english
        self.price = ai.price
        self.order = ai.order
    }
 
}

@Generable
struct AIMenuItem {
    var section: String
    var japanese: String
    var price: String?
    var order: Int?
}


struct KataItem: Codable {
    var japanese: String
    var english: String
    // var furi: String?
    // var reading: String?
}

struct MenuWord: Codable {
    let katakana: String
    let english: String
}


struct JMDict: Decodable {
    let words: [JMDictWord]
}

struct JMDictWord: Decodable {
    let id: String
    let kanji: [JMDictKanji]
    let kana: [JMDictKana]
    let sense: [JMDictSense]
}

struct JMDictKanji: Decodable {
    let text: String
    let common: Bool?
}

struct JMDictKana: Decodable {
    let text: String
    let common: Bool
}

struct JMDictSense: Decodable {
    let field: [String]
    let gloss: [JMDictGloss]
}

struct JMDictGloss: Decodable {
    let lang: String
    let text: String
    let type: String?
}

/*
 AltData
 {"japanese":"アゴニスト","english":"AGONIST"},
 
 
 menukata
 { "japanese": "居酒屋", "furi": "居酒屋(いざかや)", "reading": "Izakaya", "english": "Izakaya (japanese pub)" },
 
 menuWords
 MenuWord
 struct MenuWord: Codable {
     let katakana: String
     let english: String
 }
 
 */
