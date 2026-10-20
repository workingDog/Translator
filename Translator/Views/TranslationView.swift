//
//  TranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation


enum TransMode: String, CaseIterable {
    case ocr
    case ai
}

struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var isSaved = false
    @State private var isTranslated = false
    
    @State private var mode: TransMode? = .ocr
    
    let menuid = UUID()
    let title = "Menu \(Int.random(in: 1...1000))"
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 5) {
//                if mode == .ocr {
                    EnglishView().padding(5)
//                }
                
//                if mode == .ai {
//                    AiTranslationView()
//                }
            }
            .padding(10)
            .padding(.top, 10)
            
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        translator.saveTranslatedMenu(
                            title: title,
                            menuid: menuid,
                            modelContext: modelContext)
                    } label: {
                        ZStack {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Image(systemName: "star").foregroundStyle(.black)
                        }
                        .font(.title)
                    }
                    .buttonStyle(.plain)
                }
                
//                ToolbarItemGroup(placement: .topBarTrailing) {
//                    Button("OCR") {
//                        mode = .ocr
//                    }.tint(mode == .ocr ? .blue : .primary)
//                    
//                    Button("AI") {
//                        mode = .ai
//                    }.tint(mode == .ai ? .blue : .primary)
//                }
                
                ToolbarItem(placement: .principal) {
                    Button {
                        doTranslation()
                    } label: {
                        Image(systemName: "translate").font(.title)
                    }
                    .buttonStyle(.glass)
                    .disabled(isTranslated)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        translator.selectedImageItem?.isCorrected.toggle()
                    } label: {
                        Image(systemName: "perspective").font(.title2)
                    }
                    .disabled(isTranslated)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        translator.selectedImageItem?.isRotated.toggle()
                    } label: {
                        Image(systemName: "rotate.right").font(.title2)
                    }
                    .disabled(isTranslated)
                }
                
                ToolbarItem(placement: .status) {
                    Text(title)
                }
                
            }
        }
        // when translator.translationConfiguration changes, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            translator.isProcessing = true
            await translator.translateOCRItems(using: session)
            print("\n---> translateOCRItems done")
            translator.applyMenuWords()
            print("---> applyMenuWords done\n")
            translator.isProcessing = false
        }
    }
    
    func doTranslation() {
        Task {
            translator.isProcessing = true
            // do OCR
            await translator.doRecognition()
            // activate .translationTask(...) for translation
            translator.translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: Locale.Language(identifier: "en"),
                preferredStrategy: .highFidelity
            )
            isTranslated = true
        }
    }
    
}
