//
//  EnglishMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation


struct EnglishMenuView: View {
    let model: MenuTranslatorModel
    let onBackToJapanese: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("English Translation")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(model.englishText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Edit Japanese Text") {
                    onBackToJapanese()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Translation")
        .navigationBarTitleDisplayMode(.inline)
    }
}


