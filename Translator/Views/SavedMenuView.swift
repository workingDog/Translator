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
    @State private var showClean = false
    
    var body: some View {
        @Bindable var translator = translator
        
        ZStack {
            AppBackground().ignoresSafeArea()
            
            if let image = UIImage(data: menu.imageData) {
                let (savedOCRData, savedMenuAI) = decodeMenu(menu)
                
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Text(menu.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                    
                    HStack {
                        Image(systemName: "textformat.size").bold()
                        Slider(value: $translator.fontScale, in: 0.5...1.8, step: 0.05)
                            .padding(15)
                            .frame(height: 50)
                        Text("\(Int(translator.fontScale * 100))%")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "distribute.vertical").bold()
                        
                        Slider(value: $translator.spacing, in: 1...250, step: 1.0).padding(15)
                        
                        Text("\(Int(translator.spacing))")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        Picker("", selection: $showClean) {
                            Text("Overlay").tag(false)
                            Text("Transparent").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(10)
                        .frame(width: 200)
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    let imagin = showClean ? UIImage(size: image.size) : image
                    
                    ZoomableImageView(
                        image: imagin,
                        items: savedOCRData?.items ?? [],
                        menu: savedMenuAI
                    )
                    
                    
                    //                    if let menu = savedMenuAI {
                    //                        ScrollView {
                    //                            ForEach(menu.sections.indices, id: \.self) { sectionIndex in
                    //                                Divider()
                    //                                let section = menu.sections[sectionIndex]
                    //                                Text(section.title).font(.title2).bold()
                    //                                ForEach(section.items.indices, id: \.self) { itemIndex in
                    //                                    let item = section.items[itemIndex]
                    //                                    HStack {
                    //                                        Text(item.english)
                    //                                        Spacer()
                    //                                        Text(item.price ?? "")
                    //                                    }
                    //                                }
                    //                            }
                    //                        }
                    //                        .padding(10)
                    //                    }
                    
                }
                .frame(maxWidth: .infinity)
                .navigationBarTitleDisplayMode(.large)
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
    
    func decodeMenu(_ menu: TranslatedMenu) -> (ocr: SavedOCRData?, ai: MenuTranslation?) {
        let ocr = menu.ocrData.flatMap { try? JSONDecoder().decode(SavedOCRData.self, from: $0) }
        let ai = menu.aiData.flatMap { try? JSONDecoder().decode(MenuTranslation.self, from: $0) }
        return (ocr, ai)
    }
    
}
