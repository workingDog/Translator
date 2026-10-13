//
//  TranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation


struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var isSaved = false
    @State private var isTranslated = false
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            EnglishView().padding(5)
                .toolbar {
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if !isSaved {
                                translator.saveTranslatedMenu(
                                    title: "Menu",
                                    modelContext: modelContext)
                                isSaved = true
                            }
                        } label: {
                            ZStack {
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Image(systemName: "star").foregroundStyle(.black)
                            }
                            .font(.title)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaved)
                    }
                    
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
                        .buttonStyle(.glass)
                        .disabled(isTranslated)
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            translator.selectedImageItem?.isRotated.toggle()
                        } label: {
                            Image(systemName: "rotate.right").font(.title2)
                        }
                        .buttonStyle(.glass)
                        .disabled(isTranslated)
                    }
                }
        }
        // when translator.translationConfiguration changes, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            translator.isProcessing = true
            await translator.translateOCRItems(using: session)
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
