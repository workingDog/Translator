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
