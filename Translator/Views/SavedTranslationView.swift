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
            ZStack {
                AppBackground().ignoresSafeArea()
                
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
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.background.opacity(0.35))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.secondary.opacity(0.35), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationTitle("Saved translations")
            }
        }
    }
}
