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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if translator.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                
                OCRImageView()
        
            }
            .padding()
        }
        .task {
            print("----> EnglishView task")
            translator.translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: Locale.Language(identifier: "en")
            )
        }
        // when translator.translationConfiguration changed, it will activate this task
        .translationTask(translator.translationConfiguration) { session in
            print("----> before EnglishView translationTask")
            await translator.translateOCRItems(using: session)
        }
        .navigationTitle("English")
        .navigationBarTitleDisplayMode(.inline)
    }
}
