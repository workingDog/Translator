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
    @Environment(\.dismiss) private var dismiss
    @Environment(TranslatorModel.self) private var translator
    
    @State private var mode: TransMode? = .ai
    @State private var showEditSheet = false
    @State private var showSave = false

    @State private var title = "Menu \(Int.random(in: 1...1000))"
    @State private var resto = "Resto \(Int.random(in: 1...1000))"
    
    let menuid = UUID()
    
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 5) {
//                if mode == .ocr {
//                    EnglishView().padding(5)
//                }
                if mode == .ai {
                    AiTranslationView()
                }
            }
            .padding(10)
            .padding(.top, 10)
            .confirmationDialog("Save Translation?",isPresented: $showSave,titleVisibility: .visible) {
                Button("Save") {
                    translator.saveTranslatedMenu(
                        title: title,
                        resto: resto,
                        menuid: menuid,
                        modelContext: modelContext)
                    dismiss()
                }
                Button("Don't Save", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        translator.saveTranslatedMenu(
//                            title: title,
//                            resto: resto,
//                            menuid: menuid,
//                            modelContext: modelContext)
//                    } label: {
//                        ZStack {
//                            Image(systemName: "star.fill").foregroundStyle(.yellow)
//                            Image(systemName: "star").foregroundStyle(.black)
//                        }
//                        .font(.title2)
//                    }
//                    .buttonStyle(.plain)
//                    .disabled(translator.isProcessing)
//                }
                
//                ToolbarItemGroup(placement: .topBarTrailing) {
//                    Button("OCR") {
//                        mode = .ocr
//                    }.tint(mode == .ocr ? .blue : .primary)
//                    .disabled(translator.isProcessing)
//                    
//                    Button("AI") {
//                        mode = .ai
//                    }.tint(mode == .ai ? .blue : .primary)
//                    .disabled(translator.isProcessing)
//                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSave = true
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Button {
                        doTranslation()
                    } label: {
 //                       VStack {
                            Image(systemName: "translate").font(.title3)
//                            Text(mode?.rawValue ?? "")
//                        }
//                        .font(.title3)
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
                    Button(resto) {
                        showEditSheet = true
                    }
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
        .alert("Rename menu", isPresented: $showEditSheet) {
            VStack {
                TextField("Restaurant", text: $resto)
                TextField("Menu name", text: $title)
            }
            Button("OK") {
                resto = resto.trim()
                title = title.trim()
            }
        }
    }
    
    /*
    func doTranslation1() {
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
    */

    func doTranslation() {
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
