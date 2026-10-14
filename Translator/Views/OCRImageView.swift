//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


struct OCRImageView: View {
    @Environment(TranslatorModel.self) private var translator

    let showTransparent: Bool
    
    var body: some View {
        if let imgItem = translator.selectedImageItem {
            
            let image = imgItem.isCorrected ? imgItem.corectedImg : imgItem.uimage
            let imagin = showTransparent ? UIImage(size: image.size) : image
            
            ZoomableImageView(image: imagin, items: translator.ocrTextItems)
            
        }
    }

}
