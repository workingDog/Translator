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
    
    @State private var showClean = false
    
    var body: some View {
        @Bindable var translator = translator
        
        ScrollView {
            
            VStack(alignment: .leading, spacing: 10) {
                
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size").bold()
                        Slider(value: $translator.fontScale, in: 0.5...1.8, step: 0.05)
                        Text("\(Int(translator.fontScale * 100))")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }.padding(5)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "distribute.vertical").bold()
                        Slider(value: $translator.spacing, in: 0...250, step: 1)
                        Text("\(Int(translator.spacing))")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }.padding(5)
                    
                    if translator.isProcessing {
                        HStack {
                            Spacer()
                            ProgressView().controlSize(.large)
                            Spacer()
                        }
                    } else {
                        Picker("Image style", selection: $showClean) {
                            Text("Overlay").tag(false)
                            Text("Transparent").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 222)
                        .padding(.bottom, 5)
                    }
                }
                .padding(5)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, 5)
                
                OCRImageView(isClean: showClean)
                
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
