//
//  AiTranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/08.
//
import SwiftUI


struct AiTranslationView: View {
    @Environment(TranslatorModel.self) private var translator
    
    private var sections: [String] {
        var seen: Set<String> = []
        return translator.menuItems
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
            .compactMap { item in
                seen.insert(item.section).inserted ? item.section : nil
            }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if translator.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView().controlSize(.large)
                        Spacer()
                    }
                }
                
//                if let img = translator.selectedImageItem?.getImage() {
//                    Image(uiImage: img)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(maxWidth: .infinity)
//                }
                
                ForEach(sections, id: \.self) { section in
                    Divider()
                    
                    Text(section).font(.title2).bold()
                    
                    ForEach(translator.menuItems.filter { $0.section == section }.sorted { ($0.order ?? 0) < ($1.order ?? 0) }, id: \.japanese) { item in
                        
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
    }
}
