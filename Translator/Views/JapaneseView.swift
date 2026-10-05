//
//  JapaneseView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation


struct JapaneseView: View {
    @Environment(TranslatorModel.self) private var translator

    @Binding var route: NavRoute?
    
    var body: some View {
        @Bindable var translator = translator
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Japanese OCR")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Correct any OCR mistakes before translating.")

            TextEditor(text: $translator.japaneseText)
                .frame(minHeight: 250)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 10).stroke(.quaternary)
                }
            Spacer()
        }
        .padding()
        .navigationTitle("Japanese")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    route = .english
                } label: {
                    Image(systemName: "translate").font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task {
            print("----> JapaneseView task")
            await translator.doRecognition()
        }
    }
}
