//
//  SavedTranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData


struct MenuListView: View {
    
    @Query(sort: \TranslatedMenu.createdAt, order: .reverse)
    private var menus: [TranslatedMenu]
    
    @State private var searchText = ""
    
    private var groupedMenus: [(resto: String, menus: [TranslatedMenu])] {
        let filteredMenus = searchText.isEmpty
        ? menus
        : menus.filter {
            $0.resto.trim().localizedCaseInsensitiveContains(searchText) ||
            $0.title.trim().localizedCaseInsensitiveContains(searchText)
        }
        let grouped = Dictionary(grouping: filteredMenus) { $0.resto }
        return grouped.map { (resto: $0.key, menus: $0.value) }
            .sorted {
                $0.resto.trim().localizedCaseInsensitiveCompare($1.resto.trim()) == .orderedAscending
            }
    }
    
    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            
            List {
                ForEach(groupedMenus, id: \.resto) { group in
                    DisclosureGroup {
                        ForEach(group.menus) { menu in
                            NavigationLink {
                                SavedMenuView(menu: menu)
                            } label: {
                                HStack {
                                    if let image = UIImage(data: menu.imageData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    Text(menu.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(8)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "fork.knife")
                                .font(.title)
                                .foregroundStyle(.tint)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(group.resto)
                                    .font(.headline)
                                
                                if let date = group.menus.map(\.createdAt).max() {
                                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("\(group.menus.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.15))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 3, trailing: 10))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Search restaurants")
            .navigationTitle("Menu list")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
}
