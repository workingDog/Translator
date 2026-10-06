//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import PhotosUI
import Translation
import Vision
import UIKit
import ImageIO



struct OCRImageView: View {
    @Environment(TranslatorModel.self) private var translator
    
    var body: some View {
        if let image = translator.selectedImage {
            GeometryReader { geometry in
                ZStack {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()

                    ForEach(translator.ocrTextItems) { item in
                        OCRTextOverlay(
                            item: item,
                            text: translator.translatedText[item.id] ?? item.text,
                            imageSize: image.size,
                            containerSize: geometry.size
                        )
                    }
                }
            }
            .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
        }
    }
}

// display the translated text 
struct OCRTextOverlay: View {

    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize

    var body: some View {
        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )

        let displayedSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        let offsetX = (containerSize.width - displayedSize.width) / 2
        let offsetY = (containerSize.height - displayedSize.height) / 2
        
        let box = item.boundingBox

        Text(text)
            .font(.system(size: max(box.height * displayedSize.height * 0.7, 8)))
            .foregroundStyle(.black)
            .padding(.horizontal, 2)
            .background(.white)
            .position(
                x: offsetX + box.midX * displayedSize.width,
                y: offsetY + (1 - box.midY) * displayedSize.height
            )
        
        Rectangle()
            .stroke(.red, lineWidth: 2)
            .frame(width: box.width * displayedSize.width, height: box.height * displayedSize.height)
            .position(
                x: offsetX + box.midX * displayedSize.width,
                y: offsetY + (1 - box.midY) * displayedSize.height
            )
        
    }

}
