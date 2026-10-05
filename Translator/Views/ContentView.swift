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
    @Environment(TranslatorModel.self) private var translator
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var route: NavRoute?
    @State private var showCamera = false
    @State private var cameraCancel = false
    @State private var selectedImages: [ImageItem] = []

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                selectedImagesView
                if let errorMessage = translator.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .padding()
            .navigationTitle("Translator")
            .navigationDestination(item: $route) { route in
                switch route {
                    case .japanese: JapaneseView(route: $route)
                    case .english: EnglishView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera").font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                }
                ToolbarItem(placement: .automatic) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Choose Menu Photo", systemImage: "photo")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImages: $selectedImages, cameraCancel: $cameraCancel)
        }
    }
    
    @ViewBuilder
    var selectedImagesView: some View {
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            translator.selectedImage = imgItem.uimage
                            route = .japanese
                        }
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
            selectedImages.append(ImageItem(uimage: image))
            translator.selectedImage = image
            await translator.doRecognition()
        } catch {
            translator.errorMessage = error.localizedDescription
        }
    }
}
