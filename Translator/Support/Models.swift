//
//  SwiftDataModels.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData


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
    var createdAt: Date
    var ocrData: Data?
//    var aiData: Data?

    init(menuid: UUID, title: String, imageData: Data, ocrData: Data) {
        self.menuid = menuid
        self.title = title
        self.imageData = imageData
        self.ocrData = ocrData
        self.createdAt = .now
    }

}

nonisolated struct OCRTextItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var engText: String
    var boundingBox: CGRect
    
    init(id: UUID = UUID(), text: String, engText: String, boundingBox: CGRect) {
        self.id = id
        self.text = text
        self.engText = engText
        self.boundingBox = boundingBox
    }
}

struct SavedOCRData: Codable {
    let items: [OCRTextItem]
}
