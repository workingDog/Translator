//
//  ContentView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import SwiftData
import PhotosUI


enum PhotoError: LocalizedError {
    case invalidData
    
    var errorDescription: String? {
        "The selected photo could not be loaded."
    }
}

enum NavRoute: Hashable {
    case japanese
    case english
    case store
    case smart
    case translation
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var route: NavRoute?
    @State private var selectedImages: [ImageItem] = []
    
    @State private var showCamera = false
    @State private var showSmart = false
    @State private var showImport = false
    @State private var cameraCancel = false

    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                
                VStack(spacing: 12) {
                    
                    Text("Translator")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.top, -30)
                    
                    selectedImagesView
                    
                    if let errorMessage = translator.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
                .padding()
                .navigationDestination(item: $route) { route in
                    if route == .store {
                        SavedTranslationView()
                    }
                    if route == .translation {
                        TranslationView()
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
                    ToolbarItem(placement: .topBarTrailing) {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Choose Menu Photo", systemImage: "photo")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showImport = true
                        } label: {
                            Image(systemName: "tray.and.arrow.down")
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
        .fileImporter(
            isPresented: $showImport,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            do {
                let urls = try result.get()
                doImportImage(urls: urls)
            } catch {
                print(error)
            }
        }
        // for testing
        .task {
            if let uimg = UIImage(named: "testmenu2") {
                selectedImages.append(ImageItem(uimage: uimg))
            }
            if let uimg = UIImage(named: "testmenu") {
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
                        route = .translation
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
    
    func doImportImage(urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        Task {
            let accessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let data = try Data(contentsOf: sourceURL)
                guard let image = UIImage(data: data) else {
                    print("Unable to create image from file")
                    return
                }
                selectedImages.append(ImageItem(uimage: image))
            } catch {
                print("doImportImage error:", error)
            }
        }
    }
    
}
