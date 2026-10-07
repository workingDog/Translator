//
//  SavedTranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData


struct SavedTranslationView: View {
    
    @Query(sort: \TranslatedMenu.createdAt, order: .reverse)
    private var menus: [TranslatedMenu]
    
    var body: some View {
        NavigationStack {
            List(menus) { menu in
                NavigationLink {
                    SavedMenuView(menu: menu)
                } label: {
                    HStack {
                        if let image = UIImage(data: menu.imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Text(menu.title)
                    }
                }
            }
            .navigationTitle("Saved translations")
        }
    }
}

struct SavedMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    let menu: TranslatedMenu
    
    @State private var showEditSheet = false
    @State private var shouldDelete = false
    
    
    var body: some View {
        if let image = UIImage(data: menu.imageData) {
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
                
                ZoomableImageView(image: image, items: [], translations: [:])
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        shouldDelete = true
                    } label: {
                        Image(systemName: "trash").font(.title2)
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
