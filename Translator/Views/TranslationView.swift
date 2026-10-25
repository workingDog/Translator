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
    
    @State private var mode: TransMode? = .ocr
    
    let menuid = UUID()
    let title = "Menu \(Int.random(in: 1...1000))"
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 5) {
                if mode == .ocr {
                    EnglishView().padding(5)
                }
                if mode == .ai {
                    AiTranslationView()
                }
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
                        .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(translator.isProcessing)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("OCR") {
                        mode = .ocr
                    }.tint(mode == .ocr ? .blue : .primary)
                    .disabled(translator.isProcessing)
                    
                    Button("AI") {
                        mode = .ai
                    }.tint(mode == .ai ? .blue : .primary)
                    .disabled(translator.isProcessing)
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        doTranslation()
                    } label: {
                        VStack {
                            Image(systemName: "translate")
                            Text(mode?.rawValue ?? "")
                        }
                        .font(.title3)
                    }
                    .buttonStyle(.glass)
                    .disabled(translator.isProcessing)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        translator.selectedImageItem?.isCorrected.toggle()
                    } label: {
                        Image(systemName: "perspective").font(.title2)
                    }
                    .disabled(translator.isProcessing)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        translator.selectedImageItem?.isRotated.toggle()
                    } label: {
                        Image(systemName: "rotate.right").font(.title2)
                    }
                    .disabled(translator.isProcessing)
                }
                
                ToolbarItem(placement: .status) {
                    Text(title)
                }
                
            }
        }
        // when translator.translationConfiguration changes, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            translator.isProcessing = true
            defer { translator.isProcessing = false }

            if mode == .ocr {
                await translator.translateOCRItems(using: session)
            } else {
                await translator.doAiProcess(using: session)
            }
        }
        
    }
    
    func doTranslation() {
        Task {
            translator.isProcessing = true
            if mode == .ocr {
                await translator.doRecognition()
                if translator.translationConfiguration == nil {
                    translator.translationConfiguration = TranslationSession.Configuration(
                        source: Locale.Language(identifier: "ja"),
                        target: Locale.Language(identifier: "en"),
                        preferredStrategy: .highFidelity
                    )
                } else {
                    translator.translationConfiguration?.invalidate()
                }
            } else {
                await translator.doAiTranslate()
            }
            translator.isProcessing = false
        }
    }

    func doTranslation1() {
        Task {
            translator.isProcessing = true
            if mode == .ocr {
                await translator.doRecognition()
            }
            translator.isProcessing = false

            if translator.translationConfiguration == nil {
                translator.translationConfiguration = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "ja"),
                    target: Locale.Language(identifier: "en"),
                    preferredStrategy: .highFidelity
                )
            } else {
                translator.translationConfiguration?.invalidate()
            }
        }
    }
    
}
