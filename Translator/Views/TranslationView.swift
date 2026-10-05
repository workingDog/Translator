//
//  TranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import Translation


struct TranslationView: View {
    let japaneseText: String

    @State private var englishText = ""
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Japanese").font(.headline)

            Text(japaneseText)

            Button("Translate") {
                configuration = TranslationSession.Configuration(
                    source: Locale.Language(identifier: "ja"),
                    target: Locale.Language(identifier: "en")
                )
            }

            if !englishText.isEmpty {
                Divider()
                Text("English").font(.headline)
                Text(englishText)
            }
        }
        .padding()
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(japaneseText)
                englishText = response.targetText
            } catch {
                englishText = "Translation failed: \(error.localizedDescription)"
            }
        }
    }
}
