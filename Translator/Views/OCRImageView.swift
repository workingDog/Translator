//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


struct OCRImageView: View {
    @Environment(TranslatorModel.self) private var translator

    let isClean: Bool
    
    var body: some View {
        if let image = translator.selectedImage {
            let imagin  = isClean ? UIImage(size: image.size) : image
            ZoomableImageView(
                image: imagin,
                items: translator.ocrTextItems,
                menu: nil)
        }
    }

}
