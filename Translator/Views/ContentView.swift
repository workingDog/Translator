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
    @State private var showSettings = false
    @State private var cameraCancel = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                
                VStack(spacing: 10) {
                    Text("Translator")
                        .font(.system(size: 28, weight: .bold))
                    
                    selectedImagesView
                    
                    if let errorMessage = translator.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            route = .store
                        } label: {
                            Image(systemName: "list.number").font(.title2)
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
            if let uimg = UIImage(named: "testSkew") {  // test5 testSkew
                selectedImages.append(ImageItem(uimage: uimg))
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImages: $selectedImages, cameraCancel: $cameraCancel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(translator)
                .presentationDetents([.medium])
        }
    }
    
    @ViewBuilder
    var selectedImagesView: some View {
        List {
            ForEach(Array(selectedImages.enumerated()), id: \.element.id) { index, imgItem in
                
                HStack {
                    
                    if translator.showPerspective {
                        Button {
                            selectedImages[index].isCorrected.toggle()
                        } label: {
                            Image(systemName: "perspective")
                                .font(.title)
                                .foregroundStyle(imgItem.isCorrected ? Color.red : Color.primary)
                                .overlay {
                                    if imgItem.isCorrected {
                                        Circle().stroke(Color.red, lineWidth: 1.5)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    let theImg = imgItem.isCorrected ? imgItem.corectedImg : imgItem.uimage
                    
                    Image(uiImage: theImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 330, height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            translator.resetTranslation()
                            translator.selectedImage = theImg
                            route = .translation
                        }
                        .padding(5)
                }
                .listRowInsets(EdgeInsets(top: 2.5,leading: 0,bottom: 2.5,trailing: 0))
            }
            .onDelete(perform: deleteImage)
            .listRowBackground(Color.clear)
 //           .listRowSeparator(.hidden)
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






/*
 List {
 ForEach(selectedImages) { imgItem in
 ZStack {
 Image(uiImage: imgItem.uimage)
 .resizable()
 .aspectRatio(contentMode: .fit)
 .frame(width: 333, height: 333)
 .clipShape(RoundedRectangle(cornerRadius: 15))
 .clipped()
 .contentShape(Rectangle())
 .onTapGesture {
 translator.resetTranslation()
 translator.selectedImage = imgItem.uimage
 route = .translation
 }
 
 if showCorrection, let testImg, testImg.id == imgItem.id {
 if let correctedImage = correctImage(imgItem.uimage) {
 // set the new image to this correct image
 Image(uiImage: correctedImage)
 .resizable()
 .aspectRatio(contentMode: .fit)
 .frame(width: 333, height: 333)
 .clipShape(RoundedRectangle(cornerRadius: 15))
 .clipped()
 .allowsHitTesting(false)
 
 } else {
 Text("Rectangle not detected").foregroundStyle(.red)
 }
 } else {
 // undo the corrected image
 
 
 }
 
 }
 .listRowBackground(Color.clear)
 .listRowInsets(EdgeInsets(top: 4, leading: 1, bottom: 4, trailing: 1))
 }
 .onDelete(perform: deleteImage)
 }
 
 
 //
 //    @ViewBuilder
 //    var selectedImagesView: some View {
 //
 //        List {
 //            ForEach(selectedImages) { imgItem in
 //                HStack {
 //
 //                    Button {
 //                        if let index = selectedImages.firstIndex(where: {$0.id == imgItem.id}) {
 //                            selectedImages[index].isCorrected.toggle()
 //                        }
 //                    } label: {
 //                        Image(systemName: selectedImages.contains(where: {$0.id == imgItem.id})
 //                              ? "checkmark.circle.fill"
 //                              : "circle")
 //                        .font(.title2)
 //                        .foregroundStyle(selectedImages.contains(where: {$0.id == imgItem.id})
 //                                         ? Color.green
 //                                         : .secondary
 //                        )
 //
 //                        .frame(maxWidth: .infinity, alignment: .leading)
 //                        .contentShape(Rectangle())
 //                    }
 //                    .buttonStyle(.plain)
 //
 //                    Image(uiImage: imgItem.uimage)
 //                        .resizable()
 //                        .aspectRatio(contentMode: .fit)
 //                        .frame(width: 333, height: 333)
 //                        .scaledToFit()
 //                        .clipShape(RoundedRectangle(cornerRadius: 15))
 //                        .clipped()
 //                        .contentShape(Rectangle())
 //                        .onTapGesture {
 //                            print("---> selected")
 ////                            translator.resetTranslation()
 ////                            translator.selectedImage = imgItem.uimage
 ////                            route = .translation
 //                        }
 //
 //                    Spacer()
 //                }
 //            }
 //            .onDelete(perform: deleteImage)
 //        }
 //
 //        .listStyle(.plain)
 //        .scrollContentBackground(.hidden)
 //    }
 
 
 */


