//
//  AiTranslationView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/08.
//
import SwiftUI
import SwiftData
import Translation
import FoundationModels
import Vision


struct AiTranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TranslatorModel.self) private var translator

    @State private var menu: MenuTranslation?
    
    
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
                
                if let img = translator.selectedImage {
                    Image(uiImage: img).resizable()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                
                if let menu {
                    ForEach(menu.sections.indices, id: \.self) { sectionIndex in
                        Divider()
                        let section = menu.sections[sectionIndex]
                        Text(section.title).font(.title2).bold()
                        ForEach(section.items.indices, id: \.self) { itemIndex in
                            let item = section.items[itemIndex]
                            HStack {
                                Text(item.english)
                                Spacer()
                                Text(item.price ?? "")
                            }
                        }
                    }
                }
            }
            .padding(10)
        }
        .task {
            translator.isProcessing = true
            menu = await translator.doAiTranslation8()
            translator.isProcessing = false
        }
    }

}
