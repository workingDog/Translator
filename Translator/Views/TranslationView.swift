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


struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var isSaved = false
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            EnglishView().padding(10)
                .toolbar {
                    
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Button {
                                doTranslation()
                            } label: {
                                Image(systemName: "translate")
                            }
                            .buttonStyle(.glass)
                            
                            Button {
                                if !isSaved {
                                    translator.saveTranslatedMenu(
                                        title: "Restaurant Menu",
                                        modelContext: modelContext)
                                    isSaved = true
                                }
                            } label: {
                                ZStack {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                    Image(systemName: "star").foregroundStyle(.black)
                                }
                                .font(.title2)
                            }
                            .buttonStyle(.glass)
                            .disabled(isSaved)
                        }
                        
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            if var item = translator.selectedImageItem {
                                item.isCorrected.toggle()
                                translator.updateImageItem(corrected: item.isCorrected)
                            }
                        } label: {
                            Image(systemName: "perspective").font(.title2)
                        }
                        .buttonStyle(.glass)
                        
                        Button {
                            if var item = translator.selectedImageItem {
                                item.isRotated.toggle()
                                translator.updateImageItem(rotated: item.isRotated)
                            }
                        } label: {
                            Image(systemName: "rotate.right").font(.title2)
                        }
                        .buttonStyle(.glass)
                    }
                }
        }
    }
    
    func doTranslation() {
        Task {
            translator.isProcessing = true
            // do OCR
            await translator.doRecognition()
            // do translation
            translator.translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: Locale.Language(identifier: "en"),
                preferredStrategy: .highFidelity
            )
        }
    }
    
}
