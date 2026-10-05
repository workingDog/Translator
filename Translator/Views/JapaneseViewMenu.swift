//
//  JapaneseViewMenu.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation


struct JapaneseMenuView: View {
    @Bindable var model: MenuTranslatorModel
    let onTranslate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Japanese OCR")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Correct any OCR mistakes before translating.")

            TextEditor(text: $model.japaneseText)
                .frame(minHeight: 250)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.quaternary)
                }

            Button("Translate to English") {
                onTranslate()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Japanese Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}
