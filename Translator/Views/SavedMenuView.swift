//
//  SavedMenuView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/07.
//
import SwiftUI
import SwiftData


struct SavedMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TranslatorModel.self) private var translator
    
    let menu: TranslatedMenu
    
    @State private var showEditSheet = false
    @State private var shouldDelete = false
    
    var body: some View {
        @Bindable var translator = translator
        
        ZStack {
            AppBackground().ignoresSafeArea()
            
            if let image = UIImage(data: menu.imageData) {
                let savedOCRData = menu.ocrData.flatMap { try? JSONDecoder().decode(SavedOCRData.self, from: $0) }
                VStack(spacing: 10) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Text(menu.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    HStack {
                        Image(systemName: "textformat.size").bold()
                        
                        Slider(value: $translator.fontScale, in: 0.7...1.8, step: 0.05)
                            .padding(15)
                            .frame(height: 50)
                        
                        Text("\(Int(translator.fontScale * 100))%")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    if let savedOCRData {
                        ZoomableImageView(
                            image: image,
                            items: savedOCRData.items,
                            translations: savedOCRData.translations
                        )
                    } else {
                        ZoomableImageView(
                            image: image,
                            items: [],
                            translations: [:]
                        )
                    }
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            shouldDelete = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.title2)
                        }
                    }
                }
                .alert("Rename translation", isPresented: $showEditSheet) {
                    @Bindable var menu = menu
                    TextField("Title", text: $menu.title)
                    Button("OK") { }
                }
                .alert("Delete this translation?", isPresented: $shouldDelete) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(menu)
                        try? modelContext.save()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
        }
    }
}
