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
    
    @State private var mode: TransMode?
    @State private var isSaved = false
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                
                HStack {
                    Spacer()
                    Picker("", selection: $mode) {
                        Text("None").tag(nil as TransMode?)
                        Text("OCR").tag(TransMode.ocr)
                        Text("AI").tag(TransMode.ai)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    .padding(20)
                    Spacer()
                }
                
                Spacer()
                
                if mode == .ocr {
                    EnglishView()
                }
                
                if mode == .ai {
                    AiTranslationView()
                }
                
            } // VStack
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    if !isSaved {
                        translator.saveTranslatedMenu(
                            title: "Restaurant Menu",
                            modelContext: modelContext)
                        isSaved = true
                    }
                }
                .disabled(isSaved)
            }
        }
    }

}
