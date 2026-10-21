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
        var result: [String] = []
        for item in translator.menuItems.sorted(by: { ($0.order ?? 0) < ($1.order ?? 0) }) {
            if !result.contains(item.section) {
                result.append(item.section)
            }
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if translator.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                if let img = translator.selectedImageItem?.getImage() {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                
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
