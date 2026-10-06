//
//  SwiftDataModels.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData


@Model
final class TranslatedMenu {
    
    var menuid: UUID
    var title: String
    var imageData: Data
    var ocrData: Data?
    var createdAt: Date
    
    init(title: String, imageData: Data, ocrData: Data? = nil) {
        self.menuid = UUID()
        self.title = title
        self.imageData = imageData
        self.ocrData = ocrData
        self.createdAt = Date()
    }
    
}
