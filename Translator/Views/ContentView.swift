//
//  ContentView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import PhotosUI


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var route: NavRoute?
    @State private var showCamera = false
    @State private var cameraCancel = false
    @State private var selectedImages: [ImageItem] = []

    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                
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
                        case .store: SavedTranslationView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera").font(.title2)
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Choose Menu Photo", systemImage: "photo")
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Button {
                            route = .store
                        } label: {
                            Image(systemName: "richtext.page").font(.title2)
                        }
                    }
                }
            }
        }
        // for testing
        .task {
            if let uimg = UIImage(named: "testmenu2") {
                selectedImages.append(ImageItem(uimage: uimg))
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
        List {
            ForEach(selectedImages) { imgItem in
                Image(uiImage: imgItem.uimage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 333, height: 333)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        translator.selectedImage = imgItem.uimage
                        route = .japanese
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 1, bottom: 4, trailing: 1))
            }
            .onDelete(perform: deleteImage)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func deleteImage(at offsets: IndexSet) {
        selectedImages.remove(atOffsets: offsets)
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
