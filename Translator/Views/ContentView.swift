//
//  ContentView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation
import UIKit


struct ContentView: View {
    @State private var model = MenuTranslatorModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var route: MenuRoute?
    @State private var showCamera = false
    
    @State private var cameraCancel = false
    @State private var selectedImages: [ImageItem] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
     //           photoPicker
                
                if !selectedImages.isEmpty {
                    Button {
                        route = .japanese
                    } label: {
                        Text("Recognise").font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                horizontalImagesView
                
                if model.isProcessing {
                    ProgressView("Reading menu…")
                }
                
                if let errorMessage = model.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
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
                    EnglishMenuView(model: model, onBackToJapanese: { self.route = .japanese } )
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack {
                            Image(systemName: "camera").font(.title2)
                            Text("Camera").font(.caption)
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
        // , onDismiss: {route = .japanese}
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImages: $selectedImages, cameraCancel: $cameraCancel)
        }
    }
    
    @ViewBuilder
    var horizontalImagesView: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(selectedImages) { imgItem in
                    Image(uiImage: imgItem.uimage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFill()
                        .frame(maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .clipped()
                }
            }.padding(.horizontal)
        }.padding(10)
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
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
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
