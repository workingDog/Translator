//
//  EnglishMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import Translation


struct EnglishView1: View {
    @Environment(TranslatorModel.self) private var translator
    var body: some View {
        @Bindable var translator = translator
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "textformat.size").bold()
                Slider(value: $translator.fontScale, in: 0.7...1.8, step: 0.05).padding(15)
                Text("\(Int(translator.fontScale * 100))%")
                    .monospacedDigit()
                    .frame(width: 45, alignment: .trailing)
            }
            .padding(.horizontal)
            ScrollView {
                VStack(spacing: 10) {
                    if translator.isProcessing {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                    if let image = translator.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .border(.blue)
                        
                        if !translator.isProcessing {
                            Image(uiImage: UIImage(size: image.size))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .border(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(10)
        }
        .task {
            translator.isProcessing = true
            await translator.doRecognition()
            translator.translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "ja"),
                target: Locale.Language(identifier: "en"),
                preferredStrategy: .highFidelity
            )
        }
        .translationTask(translator.translationConfiguration) { session in
            translator.isProcessing = true
            await translator.translateOCRItems(using: session)
            translator.isProcessing = false
        }
    }
}



struct EnglishView: View {
    @Environment(TranslatorModel.self) private var translator

    @State private var showClean = false
    
    var body: some View {
        @Bindable var translator = translator
        
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
            } else {
                HStack {
                    Spacer()
                    Picker("", selection: $showClean) {
                        Text("Original").tag(false)
                        Text("Clean").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(10)
                    .frame(width: 200)
                    Spacer()
                }
                .padding(.bottom, 10)
            }
            
            if showClean {
                OCRImageBlankView()
            } else {
                OCRImageView()
            }

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
