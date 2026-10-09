//
//  TranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation
import FoundationModels
import Vision


enum TransMode: String, CaseIterable {
    case ocr
    case ai
}

struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var mode: TransMode? = .ai
    @State private var isSaved = false
    
    @State private var modelTest = ""
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 5) {
                if mode == .ocr {
                    EnglishView()
                }
                
                if mode == .ai {
                    AiTranslationView()
                }
            }
            .padding(10)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                
                Button("Save") {
                    if !isSaved {
                        translator.saveTranslatedMenu(
                            title: "Restaurant Menu",
                            modelContext: modelContext)
                        isSaved = true
                    }
                }.disabled(isSaved)
                
                Button("OCR") {
                    mode = .ocr
                }.tint(mode == .ocr ? .blue : .primary)
                
                Button("AI") {
                    mode = .ai
                }.tint(mode == .ai ? .blue : .primary)
            }
        }
    }

}
