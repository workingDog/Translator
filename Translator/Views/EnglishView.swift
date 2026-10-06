//
//  EnglishMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation


struct EnglishView: View {
    @Environment(TranslatorModel.self) private var translator
    @State private var fontScale: Double = 1.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "textformat.size").bold()
                    
                    Slider(value: $fontScale, in: 0.7...1.8, step: 0.05).padding(15)
                    
                    Text("\(Int(fontScale * 100))%")
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
                
                OCRImageView(fontScale: fontScale)
        
            }
            .padding()
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
