//
//  EnglishMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import Translation


struct EnglishView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var isSaved = false
    
    var body: some View {
        @Bindable var translator = translator
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "textformat.size").bold()
                    
                    Slider(value: $translator.fontScale, in: 0.7...1.8, step: 0.05).padding(15)
                    
                    Text("\(Int(translator.fontScale * 100))%")
                        .monospacedDigit()
                        .frame(width: 45, alignment: .trailing)
                }
                .padding(.horizontal)
                
                if translator.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Button(isSaved ? "Translation saved" : "Save translation") {
                            if !isSaved {
                                translator.saveTranslatedMenu(
                                    title: "Restaurant Menu",
                                    modelContext: modelContext
                                )
                                isSaved = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaved)
                        Spacer()
                    }
                }
                
                OCRImageView()
    
            }
        }
        .task {
            translator.translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: Locale.Language(identifier: "en")
            )
        }
        // when translator.translationConfiguration changed, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            await translator.translateOCRItems(using: session)
        }
        .navigationTitle("English")
        .navigationBarTitleDisplayMode(.inline)
    }
    
}
