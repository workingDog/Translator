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
    
    @State private var modelTest = ""
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
     
                HStack {
                    Spacer()
                    
                    Picker("", selection: $mode) {
                        Text("OCR").tag(TransMode.ocr)
                        Text("AI").tag(TransMode.ai)
                    }
                    .pickerStyle(.segmented)
                    .font(.system(size: 30, weight: .semibold))
                    .frame(width: 180)
                    .padding(20)
                    
                    Spacer()
                }.padding(20)
                
                Spacer()
                
                if mode == .ocr {
                    EnglishView()
                }
                
                if mode == .ai {
                    AiTranslationView()
                }
                
            } // VStack
            .padding(10)
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






//                Button("Test Foundation Model") {
//                    Task {
//                        let model = SystemLanguageModel.default
//                        print("Before request: \(model.availability)")
//                        guard case .available = model.availability else {
//                            modelTest = "Model unavailable: \(model.availability)"
//                            return
//                        }
//                        do {
//                            let session = LanguageModelSession()
//                            let response = try await session.respond(to: "Reply with exactly: Model works")
//                            modelTest = response.content
//                        } catch {
//                            modelTest = "Error: \(error.localizedDescription)"
//                        }
//                    }
//                }.buttonStyle(.borderedProminent)
