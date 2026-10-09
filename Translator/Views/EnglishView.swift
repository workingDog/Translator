//
//  EnglishMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import Translation


struct EnglishView: View {
    @Environment(TranslatorModel.self) private var translator
    
    
    var body: some View {
        @Bindable var translator = translator
        
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
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
                }
                
                OCRImageView()
                
            }
            .padding(10)
        }
        .task {
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
        // when translator.translationConfiguration changed, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            translator.isProcessing = true
            await translator.translateOCRItems(using: session)
            translator.isProcessing = false
        }
    }
    
}
