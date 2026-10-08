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
    
    @State private var isBusi = false
    @State private var menu: MenuTranslation?
    
    var body: some View {
        
        ZStack {
            AppBackground().ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isBusi {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Button("Do test") {
                                doTest()
                            }
                            .buttonStyle(.borderedProminent)
                            Spacer()
                        }
                    }
                    
                    if let img = translator.selectedImage {
                        Image(uiImage: img).resizable()
                            .frame(width: 444, height: 444)
                    }
                    
                    if let menu {
                        ForEach(menu.sections.indices, id: \.self) { sectionIndex in
                            let section = menu.sections[sectionIndex]
                            Text(section.title)
                            ForEach(section.items.indices, id: \.self) { itemIndex in
                                let item = section.items[itemIndex]
                                Text(item.english)
                            }
                        }
                    }
                    
//                    if let ai = decoded.ai {
//                        ForEach(ai.sections, id: \.title) { section in
//                            Text(section.title)
//                            ForEach(section.items, id: \.japanese) { item in
//                                Text(item.english)
//                                if let description = item.description {
//                                    Text(description)
//                                }
//                                if let price = item.price {
//                                    Text(price)
//                                }
//                            }
//                        }
//                    }
        
                }
            }.padding(10)
        }
        .navigationTitle("Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func doTest() {
        isBusi = true
        Task {
            if let img = translator.selectedImage, let cgimg = img.cgImage {
                menu = await analyzeMenuImage(cgimg)
                isBusi = false
            }
        }
    }
   
    func analyzeMenuImage(_ image: CGImage) async -> MenuTranslation? {
        do {
            let session = LanguageModelSession(tools: [OCRTool()])
            let response = try await session.respond(generating: MenuTranslation.self) {
            """
            Read the Japanese text in the attached image labelled "MENU-IMAGE".
            Use the OCR tool to read the text.
            Translate the text into natural English.
            Organize the translated text into menu sections and individual menu items.
            Include descriptions and prices when they are present.
            """
                Attachment(image)
                    .label("MENU-IMAGE")
            }
            return response.content
        } catch {
            print(error)
            return nil
        }
    }
    
}



/*
 
 """
 Read the Japanese text in the attached image labelled "MENU-IMAGE".
 Use the OCR tool to read the text.
 Translate the text into natural English.
 Organize the translated text into menu sections and individual menu items.
 """
 
 """
 Read the Japanese text in the attached image labelled "MENU-IMAGE".
 Use the OCR tool to read the text.
 Translate the text into natural English.
 """

 */
