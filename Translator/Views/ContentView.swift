//
//  ContentView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation


enum MenuRoute: Hashable {
    case japanese
    case english
}

enum PhotoError: LocalizedError {
    case invalidData
    
    var errorDescription: String? {
        "The selected photo could not be loaded."
    }
}

struct ContentView: View {
    @State private var model = MenuTranslatorModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var route: MenuRoute?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                photoPicker
                
                if model.isProcessing {
                    ProgressView("Reading menu…")
                }
                
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Menu Translator")
            .navigationDestination(item: $route) { route in
                switch route {
                case .japanese:
                    JapaneseMenuView(
                        model: model,
                        onTranslate: {
                            model.translationConfiguration =
                            TranslationSession.Configuration(
                                source: Locale.Language(identifier: "ja"),
                                target: Locale.Language(identifier: "en")
                            )
                        }
                    )
                    
                case .english:
                    EnglishMenuView(
                        model: model,
                        onBackToJapanese: {
                            self.route = .japanese
                        }
                    )
                }
            }
        }
        .translationTask(model.translationConfiguration) { session in
            await model.translate(using: session)
            route = .english
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
    }
    
    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Choose Menu Photo", systemImage: "photo")
        }
        .buttonStyle(.borderedProminent)
    }
    
    private func loadSelectedPhoto() async {
        guard let selectedPhoto else {
            return
        }
        
        do {
            guard let data = try await selectedPhoto.loadTransferable(
                type: Data.self
            ),
                  let image = UIImage(data: data) else {
                throw PhotoError.invalidData
            }
            
            await model.process(image: image)
            
            if !model.japaneseText.isEmpty {
                route = .japanese
            }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}



/*
struct ContentView: View {
    @State private var model = MenuTranslatorModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photoPicker

                    if let image = model.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    }

                    if model.isProcessing {
                        ProgressView("Reading menu…")
                    }

                    if !model.japaneseText.isEmpty {
                        japaneseSection
                    }

                    if !model.englishText.isEmpty {
                        englishSection
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Menu Translator")
        }
        .translationTask(model.translationConfiguration) { session in
            await model.translate(using: session)
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
    }

    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Choose Menu Photo", systemImage: "photo")
        }
        .buttonStyle(.borderedProminent)
    }

    private var japaneseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Japanese OCR")
                .font(.headline)

            TextEditor(text: $model.japaneseText)
                .frame(minHeight: 160)
                .padding(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary)
                }

            Button("Translate Again") {
                model.translationConfiguration =
                    TranslationSession.Configuration(
                        source: Locale.Language(identifier: "ja"),
                        target: Locale.Language(identifier: "en")
                    )
            }
            .buttonStyle(.bordered)
        }
    }

    private var englishSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("English")
                .font(.headline)

            Text(model.englishText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhoto else {
            return
        }

        do {
            guard let data = try await selectedPhoto.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data) else {
                throw PhotoError.invalidData
            }

            await model.process(image: image)
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}

enum PhotoError: LocalizedError {
    case invalidData

    var errorDescription: String? {
        "The selected photo could not be loaded."
    }
}
*/
