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
    
    @State private var mode: TransMode? = .ocr
    
    var body: some View {
        
        ZStack {
            AppBackground().ignoresSafeArea()
            
            if let image = UIImage(data: menu.imageData) {
                Group {
                    if mode == .ocr {
                        orcView(image: image)
                    } else {
                        aiView(image: image)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("OCR") {
                            mode = .ocr
                        }.tint(mode == .ocr ? .blue : .primary)
                        
                        Button("AI") {
                            mode = .ai
                        }.tint(mode == .ai ? .blue : .primary)
                    }
                    
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
    
    func decodeMenu(_ menu: TranslatedMenu) -> SavedOCRData? {
        return menu.ocrData.flatMap { try? JSONDecoder().decode(SavedOCRData.self, from: $0) }
    }
    
    func decodeAiMenu(_ menu: TranslatedMenu) -> SavedAiData? {
        return menu.aiData.flatMap { try? JSONDecoder().decode(SavedAiData.self, from: $0) }
    }
    
    @ViewBuilder
    func orcView(image: UIImage) -> some View {
        @Bindable var translator = translator
        
        let savedOCRData = decodeMenu(menu)
        
        GeometryReader { geometry in
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
                
                VStack(spacing: 15) {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat.size").bold()
                        Slider(value: $translator.fontScale, in: 0.5...1.8, step: 0.05)
                    }.padding(5)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "distribute.vertical").bold()
                        Slider(value: $translator.spacing, in: 0...250, step: 1)
                    }.padding(5)
                    
                    Picker("Image style", selection: $showClean) {
                        Text("Overlay").tag(false)
                        Text("Transparent").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 222)
                    .padding(.bottom, 5)
                    
                }
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, 5)
                
                let imagin = showClean ? UIImage(size: image.size) : image
                
                ZoomableImageView(image: imagin, items: savedOCRData?.items ?? [])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(0)
                    .clipped()
                    .ignoresSafeArea(.container, edges: .bottom)
                
            }
            .padding(.horizontal, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    @ViewBuilder
    func aiView(image: UIImage) -> some View {

        let savedAiData = decodeAiMenu(menu)
        
        var sections: [String] {
            var result: [String] = []
            if let savedAiData {
                for item in savedAiData.items.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) }) {
                    if !result.contains(item.section) {
                        result.append(item.section)
                    }
                }
            }
            return result
        }
        
        if let savedAiData {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    ForEach(sections, id: \.self) { section in
                        Divider()
                        
                        Text(section).font(.title2).bold()
                        
                        ForEach(savedAiData.items.filter { $0.section == section }.sorted { ($0.order ?? 0) < ($1.order ?? 0) }, id: \.japanese) { item in
                            
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.english)
                                    Text(item.japanese)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if let price = item.price, !price.isEmpty {
                                    Text(price)
                                }
                                
                            }
                        }
                    }
                }
                .padding(10)
            }
        } else {
            Text("no info available")
        }
    }
    
}
